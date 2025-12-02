import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../utils/app_styles.dart';
import 'pantalla_visor_pdf.dart';

class PantallaManual extends StatelessWidget {
  // FIX: Se elimina 'const' del constructor para permitir la inicialización de _configService,
  // ya que AppConfigService() no es un constructor constante de tiempo de compilación.
  PantallaManual({super.key});

  // Instancia del servicio para obtener la URL
  late final AppConfigService _configService = AppConfigService();

  // Función simulada para abrir la URL
  void _openPdfViewer(BuildContext context, String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL del manual no está configurada.')),
      );
      return;
    }

    // Navegación a la nueva pantalla, pasando la URL como argumento
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PantallaVisorPdf(pdfUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (AppBar)
      body: Center(
        child: StreamBuilder<String?>(
          stream: _configService.getManualUrlStream(),
          builder: (context, snapshot) {
            final manualUrl = snapshot.data ?? '';

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Ocultar el botón si no hay URL configurada
            if (manualUrl.isEmpty) {
              return const Center(
                child: Text(
                  'El manual de procedimientos aún no ha sido configurado.',
                ),
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ... (Icono y textos)
                // Usamos el nuevo método _openPdfViewer
                ElevatedButton.icon(
                  onPressed: () =>
                      _openPdfViewer(context, manualUrl), // <--- CAMBIO AQUÍ
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text(
                    'Ver Manual (PDF)',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
