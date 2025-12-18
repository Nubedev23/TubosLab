import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/history_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../models/query_history.dart';
import 'pantalla_detalle_examen.dart';

class PantallaEstadisticas extends StatefulWidget {
  const PantallaEstadisticas({Key? key}) : super(key: key);

  @override
  State<PantallaEstadisticas> createState() => _PantallaEstadisticasState();
}

class _PantallaEstadisticasState extends State<PantallaEstadisticas> {
  final HistoryService _historyService = HistoryService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();

  List<QueryHistory> _historial = [];
  Map<String, int> _estadisticas = {};
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _verificarUsuario();
    _registrarVistaEstadisticas();
  }

  /// CORRECCIÓN: Verificar correctamente si el usuario está logueado
  Future<void> _verificarUsuario() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.getCurrentUserId();

      // DEBUG: Ver qué userId tenemos
      debugPrint('Usuario ID: $userId');
      debugPrint('Es anónimo (string): ${userId == 'anonimo'}');

      //  Verificación usando el método de AuthService para detectar anónimos
      final isLoggedIn = !_authService.isAnonymous();

      debugPrint('Está logueado: $isLoggedIn');

      setState(() {
        _isLoggedIn = isLoggedIn;
      });

      // Solo cargar datos si está logueado
      if (isLoggedIn) {
        await _cargarDatos();
      }
    } catch (e) {
      debugPrint('Error al verificar usuario: $e');
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarVistaEstadisticas() async {
    await _analyticsService.logCustomEvent(
      'ver_estadisticas',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar historial y estadísticas solo si está logueado
      final historial = await _historyService.obtenerHistorialUsuario();
      final stats = await _historyService.obtenerEstadisticas();

      if (mounted) {
        setState(() {
          _historial = historial;
          _estadisticas = stats;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos de estadísticas: $e');
    }
  }

  Future<void> _limpiarHistorial() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Deseas eliminar todo tu historial de consultas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _historyService.limpiarHistorialUsuario();
      await _analyticsService.logCustomEvent(
        'limpiar_historial',
        parameters: {'items_eliminados': _historial.length},
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Historial eliminado')));
        _cargarDatos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PRIMERO: Verificar si está logueado (sin importar si tiene datos o no)
    if (!_isLoggedIn) {
      return _buildLoginRequired();
    }

    // SEGUNDO: Si está cargando, mostrar indicador
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // TERCERO: Si está logueado pero no hay historial, mostrar estado vacío
    if (_historial.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _verificarUsuario();
      },
      child: SingleChildScrollView(
        padding: AppStyles.padding,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            if (_estadisticas.isNotEmpty) ...[
              _buildExamenesPopulares(),
              const SizedBox(height: 24),
            ],
            _buildHistorialList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: AppStyles.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'Estadísticas solo para usuarios registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppStyles.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Inicia sesión para ver tu historial de consultas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Cerrar sesión anónima y volver a bienvenida
                _authService.signOut(context);
              },
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text(
                'Ir a Iniciar Sesión',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay consultas registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busca exámenes para ver tus estadísticas',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mis Estadísticas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        if (_historial.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _limpiarHistorial,
            tooltip: 'Limpiar historial',
          ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.search, color: AppStyles.primaryDark, size: 48),
            const SizedBox(height: 16),
            Text(
              _historial.length.toString(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppStyles.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total de consultas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamenesPopulares() {
    // Ordenar por frecuencia
    final sortedStats = _estadisticas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar solo los primeros 5
    final topStats = sortedStats.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exámenes más consultados',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: topStats.map((entry) {
              final percentage = (entry.value / _historial.length * 100)
                  .toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: entry.value / _historial.length,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      color: AppStyles.secondaryColor,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas 10 consultas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historial.length,
          itemBuilder: (context, index) {
            final query = _historial[index];
            final tuboColor = AppStyles.getColorForTubo(query.tubo);
            final tuboTextColor = AppStyles.getTextColorForTubo(query.tubo);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: tuboColor,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: tuboTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  query.examenNombre,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tuboColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            query.tubo,
                            style: TextStyle(
                              color: tuboTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          query.anticoagulante,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFecha(query.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  // Navegar al detalle del examen
                  if (query.examenId.isNotEmpty) {
                    Navigator.of(context).pushNamed(
                      PantallaDetalleExamen.routeName,
                      arguments: query.examenId,
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
