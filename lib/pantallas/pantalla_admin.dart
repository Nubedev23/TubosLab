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
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _esAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _authService.signOut(context);
        }
        return;
      }

      final esAdmin = await _firestoreService.esAdmin(user.uid);

      if (mounted) {
        setState(() {
          _esAdmin = esAdmin;
          _isLoading = false;
        });

        if (!esAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Acceso denegado. Solo administradores pueden acceder.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            _authService.signOut(context);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking admin access: $e');
      if (mounted) {
        setState(() {
          _esAdmin = false;
          _isLoading = false;
        });
        _authService.signOut(context);
      }
    }
  }

  Future<void> _deleteExamen(String examenId, String examenNombre) async {
    // Verificar de nuevo antes de eliminar
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para realizar esta acción.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  Widget _buildExamenItem(Examen examen) {
    final String examenId = examen.id!;
    final String examenNombre = examen.nombre;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(examenNombre),
        subtitle: Text(examen.tubo),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppStyles.primaryDark),
              onPressed: () => _navigateToEditExamen(examenId),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
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
    // Mostrar loading mientras verifica
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando permisos...'),
            ],
          ),
        ),
      );
    }

    // Si no es admin, mostrar pantalla de acceso denegado
    if (!_esAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: AppStyles.padding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 20),
                const Text(
                  'Acceso Restringido',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Solo administradores pueden acceder a esta sección.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _authService.signOut(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  label: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si ES admin, mostrar panel normal
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        automaticallyImplyLeading: false,
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
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
          IconButton(
            icon: const Icon(Icons.logout),
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

  void _navigateToNewExamen() {
    // Verificar permisos antes de navegar
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para crear exámenes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(PantallaGestionExamen.routeName);
  }

  void _navigateToEditExamen(String examenId) {
    // Verificar permisos antes de navegar
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para editar exámenes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(PantallaGestionExamen.routeName, arguments: examenId);
  }

  void _navigateToGestionManual() {
    // Verificar permisos antes de navegar
    if (!_esAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para configurar el manual.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(PantallaGestionManual.routeName);
  }
}
