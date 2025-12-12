import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart'; // NUEVO
import '../services/cache_service.dart'; // NUEVO
import '../models/examen.dart';
import 'pantalla_detalle_examen.dart';
import '../services/carrito_service.dart';
import '../services/history_service.dart';

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
  final AnalyticsService _analyticsService = AnalyticsService(); // NUEVO
  final CacheService _cacheService = CacheService(); // NUEVO
  final HistoryService _historyService = HistoryService();

  String _currentQuery = '';
  List<String> _busquedasRecientes = []; // NUEVO
  bool _mostrarBusquedasRecientes = false; // NUEVO

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _cargarBusquedasRecientes(); // NUEVO
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // NUEVO: Cargar búsquedas recientes
  Future<void> _cargarBusquedasRecientes() async {
    final busquedas = await _cacheService.obtenerBusquedasRecientes();
    if (mounted) {
      setState(() {
        _busquedasRecientes = busquedas;
      });
    }
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.trim().toLowerCase();
    if (newQuery != _currentQuery) {
      setState(() {
        _currentQuery = newQuery;
        _mostrarBusquedasRecientes = newQuery.isEmpty;
      });

      // Registrar búsqueda en Analytics si tiene más de 2 caracteres
      if (newQuery.length > 2) {
        _analyticsService.logBusquedaExamen(newQuery);
        _cacheService.guardarBusquedaReciente(newQuery);
        _cargarBusquedasRecientes(); // Recargar la lista
      }
    }
  }

  // NUEVO: Widget de búsquedas recientes
  Widget _buildBusquedasRecientes() {
    if (_busquedasRecientes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay búsquedas recientes',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Búsquedas recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryDark,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _cacheService.limpiarBusquedasRecientes();
                  _cargarBusquedasRecientes();
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _busquedasRecientes.length,
            itemBuilder: (context, index) {
              final termino = _busquedasRecientes[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(termino),
                trailing: const Icon(Icons.north_west, size: 16),
                onTap: () {
                  _searchController.text = termino;
                  setState(() {
                    _currentQuery = termino.toLowerCase();
                    _mostrarBusquedasRecientes = false;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamenItem(Examen examen) {
    return ValueListenableBuilder<List<Examen>>(
      valueListenable: _carritoService.examenesEnCarritoListenable,
      builder: (context, examenesEnCarrito, child) {
        final estaEnCarrito = _carritoService.estaEnCarrito(examen.id!);
        final tuboColor = AppStyles.getColorForTubo(examen.tubo);
        final tuboTextColor = AppStyles.getTextColorForTubo(examen.tubo);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            onTap: () {
              _historyService.guardarConsulta(examen);
              // Registrar vista en Analytics
              _analyticsService.logVistaDetalleExamen(
                examen.id!,
                examen.nombre,
              );

              Navigator.of(context).pushNamed(
                PantallaDetalleExamen.routeName,
                arguments: examen.id,
              );
            },
            leading: CircleAvatar(
              backgroundColor: tuboColor,
              child: Text(
                examen.tubo.substring(0, 1),
                style: TextStyle(
                  color: tuboTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              examen.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tuboColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    examen.tubo,
                    style: TextStyle(
                      color: tuboTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    examen.anticoagulante,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                estaEnCarrito
                    ? Icons.check_circle
                    : Icons.add_shopping_cart_outlined,
                color: estaEnCarrito ? Colors.green : AppStyles.primaryDark,
              ),
              onPressed: () {
                if (estaEnCarrito) {
                  _carritoService.removerExamen(examen.id!);
                  // Registrar en Analytics
                  _analyticsService.logRemoverDelCarrito(
                    examen.id!,
                    examen.nombre,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${examen.nombre} removido del carrito.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else {
                  _historyService.guardarConsulta(examen);
                  _carritoService.agregarExamen(examen);
                  // Registrar en Analytics
                  _analyticsService.logAgregarAlCarrito(
                    examen.id!,
                    examen.nombre,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${examen.nombre} agregado al carrito.'),
                      duration: const Duration(seconds: 1),
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
              suffixIcon: _currentQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentQuery = '';
                          _mostrarBusquedasRecientes = true;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onTap: () {
              if (_searchController.text.isEmpty) {
                setState(() {
                  _mostrarBusquedasRecientes = true;
                });
              }
            },
          ),
          const SizedBox(height: 10),

          // Mostrar búsquedas recientes o resultados
          Expanded(
            child: _mostrarBusquedasRecientes && _currentQuery.isEmpty
                ? _buildBusquedasRecientes()
                : StreamBuilder<List<Examen>>(
                    stream: _firestoreService.streamExamenesBusqueda(
                      _currentQuery,
                    ),
                    builder: (context, snapshot) {
                      if (_currentQuery.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ingresa un término para buscar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 80,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sin conexión. Mostrando resultados guardados.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No se encontró el examen "${_searchController.text.trim()}" por lo que se sugiere llamar al Laboratorio directamente.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 159, 9, 9),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      }

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
