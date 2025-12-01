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
                      'No se encontraron exámenes para \"${_searchController.text.trim()}\"',
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

//     return InkWell(
//       onTap: () {
//         Navigator.of(
//           context,
//         ).pushNamed(PantallaDetalleExamen.routeName, arguments: examen.id);
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(15),
//         decoration: AppStyles.cardDecoration.copyWith(
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 5,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Icono del tubo (usamos un icono simple por ahora)
//             Icon(
//               Icons.science_outlined,
//               color: AppStyles.primaryDark,
//               size: 30,
//             ),
//             const SizedBox(width: 15),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Aquí capitalizamos la primera letra del nombre para mostrarlo bonito
//                   Text(
//                     examen.nombre.isNotEmpty
//                         ? examen.nombre[0].toUpperCase() +
//                               examen.nombre.substring(1)
//                         : 'Examen sin nombre',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     'Área: ${examen.area ?? 'No especificada'}',
//                     style: const TextStyle(fontSize: 14, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Búsqueda de Exámenes'),
//         backgroundColor: AppStyles.primaryDark,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: AppStyles.padding.copyWith(bottom: 10),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Buscar examen (ej: glicemia, hematologia)...',
//                 prefixIcon: const Icon(
//                   Icons.search,
//                   color: AppStyles.primaryDark,
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(15.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[100],
//                 contentPadding: const EdgeInsets.all(15.0),
//               ),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<List<Examen>>(
//               // Llama a la nueva función de búsqueda en Firestore
//               stream: _firestoreService.streamExamenesBusqueda(_currentQuery),
//               builder: (context, snapshot) {
//                 if (_currentQuery.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'Ingresa un término para buscar',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   );
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   // Muestra el error en la interfaz (útil para depuración)
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }

//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'No se encontraron exámenes para \"${_searchController.text.trim()}\"',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   );
//                 }

//                 // Muestra la lista de resultados
//                 final examenes = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: examenes.length,
//                   itemBuilder: (context, index) {
//                     return _buildExamenItem(examenes[index]);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
