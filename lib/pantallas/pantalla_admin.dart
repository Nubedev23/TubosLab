import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_styles.dart';
import 'pantalla_gestion_examen.dart';
import '../models/examen.dart';
import '../services/auth_service.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  static const routeName = '/admin';

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final FirestoreService _firestoreService = FirestoreService();
  // Obtener la instancia del servicio de autenticación para cerrar sesión
  final AuthService _authService = AuthService();

  // El método de asignación de rol y el mensaje redundante han sido eliminados.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        // No mostramos el botón de retroceso por defecto.
        automaticallyImplyLeading: false,
        actions: [
          // Botón para CERRAR SESIÓN (IMPORTANTE)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Cerrar Sesión (Admin)',
            onPressed: () => _authService.signOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón para CREAR NUEVO EXAMEN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Crear Nuevo Examen'),
                onPressed: _navigateToNewExamen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Exámenes Existentes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lista de EXÁMENES para edición (Usamos StreamBuilder como en búsqueda)
            Expanded(
              child: StreamBuilder<List<Examen>>(
                stream: _firestoreService.streamExamenes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay exámenes registrados.'),
                    );
                  }

                  final examenes = snapshot.data!;
                  return ListView.builder(
                    itemCount: examenes.length,
                    itemBuilder: (context, index) {
                      final examen = examenes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(examen.nombre),
                          subtitle: Text(examen.tubo),
                          // Botón para EDITAR (Lleva a PantallaGestionExamen)
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppStyles.primaryDark,
                            ),
                            onPressed: () => _navigateToEditExamen(examen.id!),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navegación para crear nuevo examen (sin ID)
  void _navigateToNewExamen() {
    Navigator.of(context).pushNamed(PantallaGestionExamen.routeName);
  }

  // Navegación para editar examen (con ID)
  void _navigateToEditExamen(String examenId) {
    Navigator.of(context).pushNamed(
      PantallaGestionExamen.routeName,
      arguments: examenId, // Pasar el ID como argumento
    );
  }
}
