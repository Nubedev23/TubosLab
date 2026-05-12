import 'package:flutter/material.dart';
import '../services/app_config_service.dart';
import '../utils/app_styles.dart';

class PantallaGestionManual extends StatefulWidget {
  const PantallaGestionManual({super.key});
  static const routeName = '/gestion-manual';

  @override
  State<PantallaGestionManual> createState() => _PantallaGestionManualState();
}

class _PantallaGestionManualState extends State<PantallaGestionManual> {
  // CORRECCIÓN: Se agrega 'late' para evitar el error de 'Constant expression expected'
  // en la inicialización de la instancia del servicio, que no usa un constructor 'const'.
  late final _configService = AppConfigService();
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = true;
  String? _currentManualUrl;

  @override
  void initState() {
    super.initState();
    // Suscribirse al stream para obtener la URL actual y poblar el campo
    _configService.getManualUrlStream().listen((url) {
      if (mounted) {
        setState(() {
          _currentManualUrl = url;
          _urlController.text = url ?? '';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _guardarUrl() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _configService.updateManualUrl(_urlController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL del manual actualizada correctamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al guardar la URL: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Manual Digital')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppStyles.padding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Establece la URL pública del documento PDF del manual de procedimientos. Esta URL será accesible a todos los usuarios desde la aplicación.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL del Manual PDF',
                        hintText: 'Ej: https://midominio.com/manual.pdf',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La URL no puede estar vacía';
                        }
                        // Validación simple de formato URL
                        if (!value.startsWith('http')) {
                          return 'Debe ser una URL válida (ej. http:// o https://)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _guardarUrl,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Guardar URL',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_currentManualUrl != null &&
                        _currentManualUrl!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text(
                            'URL Actual:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentManualUrl!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
