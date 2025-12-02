import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';
import 'pantalla_detalle_examen.dart';
import '../services/carrito_service.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({Key? key}) : super(key: key);

  static const routeName = '/busqueda';

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final CarritoService _carritoService = CarritoService();
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
    // Convierte el texto de búsqueda a minúsculas y elimina espacios
    final newQuery = _searchController.text.trim().toLowerCase();

    // Solo actualiza si la consulta (en minúsculas) ha cambiado
    if (newQuery != _currentQuery) {
      setState(() {
        _currentQuery =
            newQuery; // <-- La consulta ahora se guarda en minúsculas
      });
    }
  }

  Widget _buildExamenItem(Examen examen) {
    return ValueListenableBuilder<List<Examen>>(
      valueListenable: _carritoService.examenesEnCarritoListenable,
      builder: (context, examenesEnCarrito, child) {
        final estaEnCarrito = _carritoService.estaEnCarrito(examen.id!);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          child: ListTile(
            onTap: () {
              Navigator.of(context).pushNamed(
                PantallaDetalleExamen.routeName,
                arguments: examen.id,
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppStyles.secondaryColor,
              child: Text(
                examen.tubo.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              examen.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Tubo: ${examen.tubo} (${examen.anticoagulante})'),
            // Botón para agregar/remover del carrito
            trailing: IconButton(
              icon: Icon(
                estaEnCarrito
                    ? Icons.check_circle
                    : Icons.add_shopping_cart_outlined,
                color: estaEnCarrito ? Colors.green : AppStyles.primaryDark,
              ),
              onPressed: () {
                if (estaEnCarrito) {
                  // Si ya está, lo removemos
                  _carritoService.removerExamen(examen.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${examen.nombre} removido del carrito.'),
                    ),
                  );
                } else {
                  // Si no está, lo agregamos
                  _carritoService.agregarExamen(examen);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${examen.nombre} agregado al carrito.'),
                    ),
                  );
                }
              },
              tooltip: estaEnCarrito
                  ? 'Quitar del carrito'
                  : 'Agregar al carrito',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.padding.copyWith(top: 10, bottom: 0),
      child: Column(
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar examen por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),

          // Lista de resultados de la búsqueda
          Expanded(
            child: StreamBuilder<List<Examen>>(
              stream: _firestoreService.streamExamenesBusqueda(_currentQuery),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontró el examen \"${_searchController.text.trim()}\" por lo que se sugiere llamar al Laboratorio directamente.',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 159, 9, 9),
                      ),
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
