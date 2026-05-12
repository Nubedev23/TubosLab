import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // agrega crypto: ^3.0.3 en pubspec.yaml

class PantallaVisorPdf extends StatefulWidget {
  final String pdfUrl;
  static const routeName = '/visor-pdf';

  const PantallaVisorPdf({required this.pdfUrl, super.key});

  @override
  State<PantallaVisorPdf> createState() => _PantallaVisorPdfState();
}

class _PantallaVisorPdfState extends State<PantallaVisorPdf> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;
  bool _desdeCache = false;

  int _pages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  bool _pdfReady = false;

  @override
  void initState() {
    super.initState();
    _cargarPdf();
  }

  // Genera un nombre de archivo único basado en la URL
  // así si la URL cambia, descarga el nuevo PDF automáticamente
  String _nombreArchivo() {
    final hash = md5.convert(utf8.encode(widget.pdfUrl)).toString();
    return 'manual_$hash.pdf';
  }

  Future<File> _archivoCacheado() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${_nombreArchivo()}');
  }

  Future<void> _cargarPdf() async {
    try {
      final archivo = await _archivoCacheado();

      // ── Si ya existe en caché, abrir directo ─────────────────────
      if (await archivo.exists()) {
        if (mounted) {
          setState(() {
            localPath = archivo.path;
            isLoading = false;
            _desdeCache = true;
          });
        }
        return;
      }

      // ── Primera vez: descargar y guardar ─────────────────────────
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        await archivo.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            localPath = archivo.path;
            isLoading = false;
            _desdeCache = false;
          });
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() {
          isLoading = false;
          errorMessage = 'Error al cargar: $msg';
        });
      }
    }
  }

  // Fuerza re-descarga borrando el caché
  Future<void> _recargarPdf() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      localPath = null;
      _pdfReady = false;
    });
    try {
      final archivo = await _archivoCacheado();
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {}
    _cargarPdf();
  }

  Future<void> _guardarEnDescargas() async {
    if (localPath == null) return;
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) throw Exception('No se pudo acceder a Descargas.');
      final destino = File('${downloadsDir.path}/Manual_Laboratorio.pdf');
      await File(localPath!).copy(destino.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guardado en: ${destino.path}'), duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusWidget() {
    if (isLoading) return const Text('Cargando...');
    if (errorMessage != null) return const Text('Error de carga', style: TextStyle(color: Colors.red));
    if (!_pdfReady) return const Text('Procesando PDF...');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Página ${_currentPage + 1}/$_pages'),
        if (_desdeCache) ...[
          const SizedBox(width: 8),
          const Icon(Icons.offline_bolt, size: 14, color: Colors.green),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildStatusWidget(),
        actions: [
          if (_pdfReady && _pdfViewController != null)
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: () => _pdfViewController!.setPage(0),
              tooltip: 'Ir al inicio',
            ),
          // Botón para forzar actualización del PDF
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarPdf,
            tooltip: 'Actualizar manual',
          ),
          if (localPath != null && !isLoading)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _guardarEnDescargas,
              tooltip: 'Descargar PDF',
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Descargando manual...', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Solo ocurre la primera vez', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          if (errorMessage != null || localPath == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 60),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage ?? 'No se pudo cargar el manual.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _recargarPdf,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return PDFView(
            filePath: localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: false,
            pageFling: false,
            fitPolicy: FitPolicy.WIDTH,
            onRender: (pages) {
              if (mounted) setState(() { _pages = pages ?? 0; _pdfReady = true; });
            },
            onPageChanged: (page, total) {
              if (mounted) setState(() => _currentPage = page ?? 0);
            },
            onViewCreated: (PDFViewController vc) => _pdfViewController = vc,
            onError: (error) {
              if (mounted) setState(() { errorMessage = 'Error del visor: $error'; _pdfReady = false; });
            },
          );
        },
      ),
    );
  }
}