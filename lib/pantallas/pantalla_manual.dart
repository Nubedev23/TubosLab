import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../services/auth_service.dart'; // Importar AuthService
import '../utils/app_styles.dart';
import 'pantalla_visor_pdf.dart';

class PantallaManual extends StatelessWidget {
  PantallaManual({super.key});

  // Instancia del servicio para obtener la URL
  final AppConfigService _configService = AppConfigService();
  final AuthService _authService = AuthService(); // Agregar AuthService

  // Función para abrir el visor PDF
  void _openPdfViewer(BuildContext context, String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La URL del manual no está configurada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegación a la pantalla del visor PDF
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PantallaVisorPdf(pdfUrl: url)),
    );
  }

  // NUEVO: Widget para login requerido
  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppStyles.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'Manual solo para usuarios registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppStyles.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Inicia sesión como Personal Clínico para acceder al manual de procedimientos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Cerrar sesión anónima y volver a bienvenida
                _authService.signOut(context);
              },
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Ir a Iniciar Sesión',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PRIMERO: Verificar si es usuario anónimo
    if (_authService.isAnonymous()) {
      return _buildLoginRequired(context);
    }

    // Si NO es anónimo, continuar con el flujo normal
    return StreamBuilder<String?>(
      stream: _configService.getManualUrlStream(),
      builder: (context, snapshot) {
        // Mientras carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hay error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: AppStyles.padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                  const SizedBox(height: 20),
                  const Text(
                    'Error al cargar la configuración del manual',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final manualUrl = snapshot.data ?? '';

        // Si no hay URL configurada
        if (manualUrl.isEmpty) {
          return Center(
            child: Padding(
              padding: AppStyles.padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Manual de Procedimientos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'El manual aún no ha sido configurado por el administrador.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por favor, contacta al administrador del sistema.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si hay URL configurada, mostrar botón para abrir el PDF
        return Center(
          child: Padding(
            padding: AppStyles.padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono del manual
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'Manual de Procedimientos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Descripción
                Text(
                  'Accede al manual completo de procedimientos de laboratorio en formato PDF',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // Botón para abrir el PDF
                ElevatedButton.icon(
                  onPressed: () => _openPdfViewer(context, manualUrl),
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
            ),
          ),
        );
      },
    );
  }
}
