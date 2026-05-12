import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../services/analytics_service.dart';
import '../services/cache_service.dart';
import '../models/examen.dart';
import 'pantalla_detalle_examen.dart';
import '../services/carrito_service.dart';
import '../services/history_service.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});
  static const routeName = '/busqueda';

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final CarritoService _carritoService = CarritoService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final CacheService _cacheService = CacheService();
  final HistoryService _historyService = HistoryService();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  String _currentQuery = '';
  String _displayQuery = '';
  Future<List<Examen>>? _resultadosFuture;

  String? _areaSeleccionada;
  String? _filtroTipo;
  bool _soloUrgencia = false;

  // ← Nuevo: true cuando el usuario pidió ver resultados explícitamente
  // (por filtro o búsqueda), aunque el query esté vacío
  bool _mostrandoResultados = false;

  List<String> _busquedasRecientes = [];
  bool _mostrarBusquedasRecientes = false;
  List<String> _sugerencias = [];

  static const List<String> _areasInternas = [
    'Química Clínica', 'Hematología', 'Microbiología', 'Hormonas',
    'Virología', 'Inmunología', 'Líquidos Biológicos', 'Parasitología',
    'Tuberculosis', 'Andrología', 'Biología Molecular', 'Urgencia',
  ];

  bool _esHorarioRutina() {
    final now = DateTime.now();
    final wd = now.weekday;
    final t = now.hour * 60 + now.minute;
    if (wd == 6 || wd == 7) return false;
    if (wd >= 1 && wd <= 4) return t >= 480 && t < 1020;
    if (wd == 5) return t >= 480 && t < 960;
    return false;
  }

  String _textoHorarioActual() {
    final wd = DateTime.now().weekday;
    const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    if (wd == 6 || wd == 7) return 'Hoy es ${dias[wd]} — solo urgencias disponibles';
    if (wd == 5) return 'Viernes — rutina hasta las 16:00';
    return '${dias[wd]} — rutina hasta las 17:00';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _cargarBusquedasRecientes();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _cargarBusquedasRecientes() async {
    final b = await _cacheService.obtenerBusquedasRecientes();
    if (mounted) setState(() => _busquedasRecientes = b);
  }

  Future<void> _ejecutarBusqueda(String query) async {
    if (!mounted) return;
    final q = query.trim().toLowerCase();

    final future = _firestoreService.searchExamenesFiltrado(
      q,
      _areaSeleccionada,
      filtroTipo: _filtroTipo,
      soloUrgencia: _soloUrgencia,
    );

    setState(() {
      _currentQuery = q;
      _resultadosFuture = future;
      _mostrandoResultados = true;
      _mostrarBusquedasRecientes = false;
    });

    if (q.length > 2) {
      _analyticsService.logBusquedaExamen(q);
      _cacheService.guardarBusquedaReciente(q);
      _cargarBusquedasRecientes();
    }

    try {
      final examenes = await future;
      if (!mounted) return;
      final sug = examenes.map((e) => e.nombre).take(5).toList();
      if (sug.isNotEmpty && _searchFocusNode.hasFocus) {
        setState(() => _sugerencias = sug);
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (_) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();

    setState(() {
      _displayQuery = q;
      _mostrarBusquedasRecientes = q.isEmpty && !_mostrandoResultados;
    });

    _debounceTimer?.cancel();

    if (q.isEmpty) {
      _removeOverlay();
      // Si hay filtros activos, re-buscar sin texto para mantener los resultados
      if (_filtroTipo != null || _soloUrgencia || _areaSeleccionada != null) {
        _debounceTimer = Timer(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _ejecutarBusqueda('');
        });
      } else {
        setState(() {
          _currentQuery = '';
          _resultadosFuture = null;
          _mostrandoResultados = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _ejecutarBusqueda(q);
    });
  }

  void _onSubmitted(String value) {
    _debounceTimer?.cancel();
    _removeOverlay();
    _searchFocusNode.unfocus();
    _ejecutarBusqueda(value);
  }

  void _showOverlay() {
    _removeOverlay();
    if (!mounted) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _sugerencias.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, size: 18),
                  title: Text(_sugerencias[i]),
                  onTap: () => _onSubmitted(_sugerencias[i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  Widget _buildBannerHorario() {
    if (_esHorarioRutina()) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_textoHorarioActual()}. Los exámenes de rutina no están disponibles ahora.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip(null, 'Todos', Icons.list),
              const SizedBox(width: 6),
              _buildChip('interno', 'Del laboratorio', Icons.business),
              const SizedBox(width: 6),
              _buildChip('derivado', 'Derivados', Icons.local_shipping_outlined),
              const SizedBox(width: 6),
              FilterChip(
                selected: _soloUrgencia,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_outlined, size: 14,
                        color: _soloUrgencia ? Colors.white : Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text('Urgencia 24/7',
                        style: TextStyle(
                            fontSize: 12,
                            color: _soloUrgencia ? Colors.white : Colors.red.shade700,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                onSelected: (_) {
                  setState(() {
                    _soloUrgencia = !_soloUrgencia;
                    if (_soloUrgencia) { _filtroTipo = null; _areaSeleccionada = null; }
                    _mostrarBusquedasRecientes = false;
                  });
                  _ejecutarBusqueda(_currentQuery);
                },
                selectedColor: Colors.red.shade600,
                backgroundColor: Colors.red.shade50,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ),
        ),

        if (!_soloUrgencia && _filtroTipo != 'derivado') ...[
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                hint: const Text('Filtrar por área interna', style: TextStyle(fontSize: 13)),
                value: _areaSeleccionada,
                isExpanded: true,
                isDense: true,
                items: _areasInternas.map((a) => DropdownMenuItem(
                    value: a, child: Text(a, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) {
                  setState(() {
                    _areaSeleccionada = v;
                    _mostrarBusquedasRecientes = false;
                    if (v != null) _filtroTipo = 'interno';
                  });
                  _ejecutarBusqueda(_currentQuery);
                },
              ),
            ),
          ),
        ],

        if (_areaSeleccionada != null || _filtroTipo != null || _soloUrgencia)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _areaSeleccionada = null;
                  _filtroTipo = null;
                  _soloUrgencia = false;
                  if (_currentQuery.isEmpty) {
                    _mostrandoResultados = false;
                    _resultadosFuture = null;
                    _mostrarBusquedasRecientes = true;
                  }
                });
                if (_currentQuery.isNotEmpty) _ejecutarBusqueda(_currentQuery);
              },
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Limpiar filtros', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String? valor, String label, IconData icon) {
    final selected = !_soloUrgencia && _filtroTipo == valor;
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: selected ? Colors.white : AppStyles.primaryDark),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
              fontSize: 12, color: selected ? Colors.white : AppStyles.primaryDark)),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _filtroTipo = valor;
          _soloUrgencia = false;
          _mostrarBusquedasRecientes = false;
          if (valor == 'derivado') _areaSeleccionada = null;
        });
        // ← FIX principal: siempre ejecutar sin importar si hay query o no
        _ejecutarBusqueda(_currentQuery);
      },
      selectedColor: AppStyles.primaryDark,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildExamenItem(Examen examen) {
    return ValueListenableBuilder<List<Examen>>(
      valueListenable: _carritoService.examenesEnCarritoListenable,
      builder: (context, _, __) {
        final estaEnCarrito = _carritoService.estaEnCarrito(examen.id!);
        final disponibleAhora = examen.estaDisponibleAhora();
        final recipColor = AppStyles.getColorForRecipiente(examen.recipiente);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          color: disponibleAhora ? Colors.white : Colors.grey.shade50,
          child: ListTile(
            onTap: () {
              _historyService.guardarConsulta(examen);
              _analyticsService.logVistaDetalleExamen(examen.id!, examen.nombre);
              Navigator.of(context).pushNamed(PantallaDetalleExamen.routeName, arguments: examen.id);
            },
            leading: CircleAvatar(
              backgroundColor: disponibleAhora ? recipColor : Colors.grey.shade400,
              child: Icon(
                examen.es_derivado ? Icons.local_shipping_outlined : Icons.science_outlined,
                color: Colors.white, size: 18,
              ),
            ),
            title: Text(
              examen.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: disponibleAhora ? Colors.black87 : Colors.grey.shade600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: disponibleAhora ? recipColor : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(examen.recipienteCorto,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    if (examen.disponible_urgencia)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('24/7',
                            style: TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (examen.es_derivado)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(examen.seccion,
                              style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      )
                    else if (examen.area != null)
                      Flexible(
                        child: Text(examen.area!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
                if (!disponibleAhora) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Solo rutina: ${examen.horario_disponibilidad}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                estaEnCarrito ? Icons.check_circle : Icons.add_shopping_cart_outlined,
                color: estaEnCarrito ? Colors.green : AppStyles.primaryDark,
              ),
              onPressed: () {
                if (estaEnCarrito) {
                  _carritoService.removerExamen(examen.id!);
                  _analyticsService.logRemoverDelCarrito(examen.id!, examen.nombre);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${examen.nombre} removido.'),
                    duration: const Duration(seconds: 1),
                  ));
                } else {
                  _historyService.guardarConsulta(examen);
                  _carritoService.agregarExamen(examen);
                  _analyticsService.logAgregarAlCarrito(examen.id!, examen.nombre);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${examen.nombre} agregado.'),
                    duration: const Duration(seconds: 1),
                  ));
                }
              },
              tooltip: estaEnCarrito ? 'Quitar del carrito' : 'Agregar al carrito',
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusquedasRecientes() {
    if (_busquedasRecientes.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('No hay búsquedas recientes', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
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
              const Text('Búsquedas recientes',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppStyles.primaryDark)),
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
            itemBuilder: (context, i) {
              final t = _busquedasRecientes[i];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(t),
                trailing: const Icon(Icons.north_west, size: 16),
                onTap: () {
                  _searchController.text = t;
                  _onSubmitted(t);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultados() {
    if (_mostrarBusquedasRecientes && !_mostrandoResultados) {
      return _buildBusquedasRecientes();
    }

    // Mostrar estado inicial solo si nadie pidió resultados todavía
    if (!_mostrandoResultados) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Busca por nombre o usa los filtros',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }

    // Spinner mientras el debounce no disparó aún
    if (_displayQuery != _currentQuery && _displayQuery.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Examen>>(
      future: _resultadosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No se pudo conectar.\nVerifica tu conexión a internet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No se encontraron resultados.\n\nSi el examen no aparece, contacte al Laboratorio directamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 15),
              ),
            ),
          );
        }

        final examenes = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${examenes.length} resultado${examenes.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: examenes.length,
                itemBuilder: (context, i) => _buildExamenItem(examenes[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyles.padding.copyWith(top: 10, bottom: 0),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          children: [
            _buildBannerHorario(),

            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSubmitted,
              decoration: InputDecoration(
                hintText: 'Buscar examen por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _displayQuery.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'Buscar ahora',
                            onPressed: () => _onSubmitted(_searchController.text),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Limpiar',
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              setState(() {
                                _currentQuery = '';
                                _displayQuery = '';
                                _resultadosFuture = null;
                                _mostrandoResultados = false;
                                _mostrarBusquedasRecientes = true;
                              });
                            },
                          ),
                        ],
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
                if (_searchController.text.isEmpty && !_mostrandoResultados) {
                  setState(() => _mostrarBusquedasRecientes = true);
                }
              },
            ),
            const SizedBox(height: 10),

            _buildFiltros(),
            const SizedBox(height: 6),

            Expanded(child: _buildResultados()),
          ],
        ),
      ),
    );
  }
}