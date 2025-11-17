import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';
import 'pantalla_detalle_examen.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({Key? key}) : super(key: key);

  static const routeName = '/busqueda';

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    // Escucha los cambios en el campo de texto para actualizar la búsqueda
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Solo actualiza si la consulta ha cambiado
    if (_searchController.text.trim() != _currentQuery) {
      setState(() {
        _currentQuery = _searchController.text.trim();
      });
    }
  }

  Widget _buildExamenItem(Examen examen) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const Icon(
          Icons.science_outlined,
          color: AppStyles.primaryDark,
          size: 30,
        ),
        title: Text(
          examen.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Tubo: ${examen.tubo}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          // Navega a la pantalla de detalles usando el ID del documento (ej: 'glicemia')
          Navigator.of(context).pushNamed(
            PantallaDetalleExamen.routeName,
            arguments: examen.id, // ID en minúsculas
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Exámenes'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar examen (ej: Glicemia, Hemoglobina)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            // El FutureBuilder espera los resultados del servicio de búsqueda
            child: FutureBuilder<List<Examen>>(
              future: _firestoreService.searchExamenes(_currentQuery),
              builder: (context, snapshot) {
                if (_currentQuery.isEmpty) {
                  return Center(
                    child: Text(
                      'Ingresa un término para buscar',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Muestra el error en la interfaz (útil para depuración)
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron exámenes para "$_currentQuery"',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                // Muestra la lista de resultados
                final examenes = snapshot.data!;
                return ListView.builder(
                  itemCount: examenes.length,
                  itemBuilder: (context, index) {
                    return _buildExamenItem(examenes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
