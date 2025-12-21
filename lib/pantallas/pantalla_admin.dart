import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/app_styles.dart';
import 'pantalla_gestion_examen.dart';
import '../models/examen.dart';
import '../services/auth_service.dart';
import 'pantalla_gestion_manual.dart';
import 'pantalla_estadisticas_admin.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final esAdmin = await _firestoreService.esAdmin(user.uid);
      if (!esAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acceso no autorizado.'),
              backgroundColor: Colors.red,
            ),
          );
          _authService.signOut(context);
        }
      }
      // ¡BORRA LA LÍNEA DE Navigator.pushReplacement DE AQUÍ!
    } catch (e) {
      debugPrint('Error checking admin access: $e');
    }
  }

  // 1. Método para manejar la eliminación
  Future<void> _deleteExamen(String examenId, String examenNombre) async {
    // Implementación de confirmación simple (podría ser un modal más complejo)
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Está seguro de que desea eliminar el examen "$examenNombre"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteExamen(examenId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Examen "$examenNombre" eliminado con éxito.'),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar el examen: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el examen.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 2. Widget de item con acciones
  Widget _buildExamenItem(Examen examen) {
    // Si el id es nulo, este ítem no debería mostrarse, pero
    // por seguridad, si llegara a ser null, usamos un fallback.
    // DADA LA DEFINICIÓN DE EXAMEN, examen.id es un String NO NULO.
    final String examenId = examen.id!; // Ya es String
    final String examenNombre = examen.nombre;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(examenNombre),
        subtitle: Text(examen.tubo),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para EDITAR (Lleva a PantallaGestionExamen)
            IconButton(
              icon: const Icon(Icons.edit, color: AppStyles.primaryDark),
              onPressed: () => _navigateToEditExamen(examenId),
            ),
            // Botón para ELIMINAR (Llama al método de eliminación)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // El ID ya está garantizado como String no nulo
                _deleteExamen(examenId, examenNombre);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        // No mostramos el botón de retroceso por defecto.
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Ver Estadísticas',
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamed(PantallaEstadisticasAdmin.routeName);
            },
          ),
          // Botón para CERRAR SESIÓN (IMPORTANTE)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Cerrar Sesión (Admin)',
            onPressed: () => _authService.signOut(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_outlined),
            tooltip: 'Configurar Manual PDF',
            onPressed: _navigateToGestionManual,
          ),
        ],
      ),
      body: Padding(
        padding: AppStyles.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón para agregar un nuevo examen
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
                stream: _firestoreService.streamExamenes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay exámenes registrados.'),
                    );
                  }

                  final examenes = snapshot.data!;
                  return ListView.builder(
                    itemCount: examenes.length,
                    itemBuilder: (context, index) {
                      final examen = examenes[index];
                      return _buildExamenItem(examen);
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
  // El parámetro ahora espera un String no nulo, que es lo que se envía desde _buildExamenItem
  void _navigateToEditExamen(String examenId) {
    Navigator.of(context).pushNamed(
      PantallaGestionExamen.routeName,
      arguments: examenId, // Pasar el ID como argumento
    );
  }

  void _navigateToGestionManual() {
    // Utilizamos la ruta que definiste en main.dart
    Navigator.of(context).pushNamed(PantallaGestionManual.routeName);
  }
}
