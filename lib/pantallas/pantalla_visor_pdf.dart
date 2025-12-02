import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // El nuevo visor
import 'package:http/http.dart' as http; // Para descargar el PDF
import 'package:path_provider/path_provider.dart'; // Para obtener la ruta temporal
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

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  // 1. Función para descargar el PDF desde la URL
  Future<void> _downloadPdf() async {
    try {
      // 1. Petición HTTP a la URL
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        // 2. Obtener el directorio temporal
        final dir = await getTemporaryDirectory();

        // 3. Crear el archivo temporal
        // Usamos un nombre único basado en la hora para evitar conflictos
        final file = File(
          '${dir.path}/manual_temp_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        // 4. Escribir los bytes descargados en el archivo local
        await file.writeAsBytes(response.bodyBytes);

        // 5. Actualizar el estado con la ruta local
        if (mounted) {
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Error al descargar el PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el manual: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual de Procedimientos')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          // 2. Mostrar el visor de PDF si ya tenemos la ruta local
          : localPath != null
          ? PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: false,
              // Puedes añadir más callbacks si lo necesitas:
              // onRender: (pages) { ... },
              // onPageChanged: (page, total) { ... },
            )
          : const Center(
              child: Text(
                'No se pudo cargar el manual. Verifique la URL.',
                style: TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}
