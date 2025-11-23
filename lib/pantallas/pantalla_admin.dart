import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../utils/app_styles.dart';
import 'pantalla_gestion_examen.dart'; // Importamos la pantalla de gestión

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  static const routeName = '/admin';

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final FirestoreService _firestoreService = FirestoreService();
  String _message = 'Pulsa el botón para asignarte el rol de administrador.';

  /// 1. Función para obtener el UID y asignar el rol.
  Future<void> _assignAdminRole() async {
    setState(() {
      _message = 'Asignando rol...';
    });

    // Obtener el usuario actualmente logueado (de Firebase Auth)
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _message = 'ERROR: No hay ningún usuario logueado en Firebase Auth.';
      });
      return;
    }

    final String userId = user.uid;

    try {
      // 2. Llamar al servicio de Firestore para escribir el rol 'admin'
      await _firestoreService.setUserRole(userId, 'admin');

      setState(() {
        _message =
            '¡Rol de Administrador asignado exitosamente! Serás redirigido.';
      });

      // Redirigir a la pantalla de gestión
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(
          context,
        ).pushReplacementNamed(PantallaGestionExamen.routeName);
      });
    } catch (e) {
      print('Error al asignar rol de administrador: $e');
      setState(() {
        _message = 'ERROR al asignar rol: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Administrador'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppStyles.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),

              const Text(
                'Permisos de Acceso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              const Text(
                'Esta pantalla solo debe ser utilizada por el primer administrador para auto-asignarse el rol. Al hacerlo, obtendrá acceso a la gestión de exámenes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // Botón para ejecutar la asignación de rol
              ElevatedButton.icon(
                onPressed: _assignAdminRole,
                icon: const Icon(Icons.star),
                label: const Text('Designarme como Administrador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Mensaje de estado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppStyles.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
