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
  final AuthService _authService = AuthService();

  // Función para mostrar el diálogo de confirmación
  void _confirmDeleteExamen(Examen examen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar el examen "${examen.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                // FIX: Usamos 'examen.id!' para resolver el error de tipo String? a String
                // El modelo Examen asegura que 'id' es no-nullable, pero si por alguna razón fuera null,
                // la aserción asegura que el código procede si el ID existe.
                if (examen.id != null && examen.id!.isNotEmpty) {
                  _deleteExamen(
                    examen.id!,
                    examen.nombre,
                  ); // Procede a eliminar
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: El ID del examen es inválido.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar el examen y manejar el feedback
  Future<void> _deleteExamen(String examenId, String examenNombre) async {
    try {
      await _firestoreService.deleteExamen(examenId);
      // Muestra mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Examen "$examenNombre" eliminado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Muestra mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el examen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Nuevo Examen',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _navigateToNewExamen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Listado de Exámenes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<Examen>>(
                // El stream ya está ordenado por nombre dentro de FirestoreService
                stream: _firestoreService.streamExamenes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar datos: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay exámenes registrados. ¡Crea el primero!',
                      ),
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
                          subtitle: Text(
                            'Tubo: ${examen.tubo} | Anticoagulante: ${examen.anticoagulante}',
                          ),
                          // Fila de botones de acción
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón para EDITAR (Lleva a PantallaGestionExamen)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppStyles.primaryDark,
                                ),
                                tooltip: 'Editar Examen',
                                onPressed: () =>
                                    _navigateToEditExamen(examen.id!),
                              ),
                              // Botón para ELIMINAR
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar Examen',
                                onPressed: () => _confirmDeleteExamen(examen),
                              ),
                            ],
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
