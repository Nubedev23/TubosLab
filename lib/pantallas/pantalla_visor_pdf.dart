import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PantallaVisorPdf extends StatefulWidget {
  final String pdfUrl;
  static const routeName = '/visor-pdf';

  const PantallaVisorPdf({required this.pdfUrl, super.key});

  @override
  State<PantallaVisorPdf> createState() => _PantallaVisorPdfState();
}

class _PantallaVisorPdfState extends State<PantallaVisorPdf> {
  // Ruta del archivo PDF descargado localmente
  String? localPath;
  bool isLoading = true;
  String? errorMessage;

  // Variables para diagnóstico
  int _pages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  bool _pdfReady = false;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  // Función para descargar el PDF desde la URL
  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}/manual_temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
            errorMessage = null; // Limpiar errores previos
          });
        }
      } else {
        // Respuesta del servidor con error
        throw Exception(
          'Respuesta del servidor: Código ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          isLoading = false;
          errorMessage = 'Error al descargar o cargar: $msg';
        });
        // Mostrar error detallado en SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar manual: $msg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Muestra el estado actual del visor en el AppBar
  Widget _buildStatusWidget() {
    if (isLoading) {
      return const Text("Cargando...");
    }
    if (errorMessage != null) {
      return const Text("Error de carga", style: TextStyle(color: Colors.red));
    }
    if (localPath == null) {
      return const Text(
        "Esperando URL...",
        style: TextStyle(color: Colors.orange),
      );
    }
    if (!_pdfReady) {
      return const Text("Procesando PDF...");
    }
    // Si el PDF está listo, mostramos la página actual
    return Text('Página: ${_currentPage + 1}/$_pages');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildStatusWidget(), // Muestra el estado aquí
        actions: [
          // Botón para ir a la primera página (útil si la carga falla a veces)
          if (_pdfReady && _pdfViewController != null)
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: () {
                _pdfViewController!.setPage(0);
              },
            ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null || localPath == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      errorMessage ?? 'No se pudo cargar la ruta local.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Asegúrese de que la URL de Firebase Firestore sea un enlace de descarga directa (como Firebase Storage o Google Drive con descarga forzada).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si localPath tiene valor, mostramos el PDFView
          return PDFView(
            filePath: localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            fitPolicy: FitPolicy.WIDTH,
            // Callback que se llama cuando el PDF ha sido renderizado
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _pages = pages ?? 0;
                  _pdfReady = true;
                  print(
                    'PDF RENDERIZADO. Total de páginas: $_pages',
                  ); // Diagnóstico
                });
              }
            },
            // Callback que se llama cuando cambia la página
            onPageChanged: (page, total) {
              if (mounted) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              }
            },
            // Callback para obtener el controlador
            onViewCreated: (PDFViewController vc) {
              _pdfViewController = vc;
            },
            // Callback si ocurre un error en el motor PDFium
            onError: (error) {
              if (mounted) {
                setState(() {
                  errorMessage = 'Error del Visor PDF: $error';
                  _pdfReady = false;
                });
                print('Error fatal en el visor: $error'); // Diagnóstico
              }
            },
          );
        },
      ),
    );
  }
}
