import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/app_styles.dart';

class PantallaEstadisticasAdmin extends StatefulWidget {
  const PantallaEstadisticasAdmin({super.key});
  static const routeName = '/estadisticas-admin';

  @override
  State<PantallaEstadisticasAdmin> createState() =>
      _PantallaEstadisticasAdminState();
}

class _PantallaEstadisticasAdminState extends State<PantallaEstadisticasAdmin> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _cargando = true;
  bool _autorizado = false;

  @override
  void initState() {
    super.initState();
    _verificarAdmin();
  }

  Future<void> _verificarAdmin() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _autorizado = false;
        _cargando = false;
      });
      return;
    }

    final esAdmin = await _firestoreService.esAdmin(user.uid);

    if (mounted) {
      setState(() {
        _autorizado = esAdmin;
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_autorizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text(
                'Acceso no autorizado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Solo administradores pueden ver esta sección'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Estadísticas'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: AppStyles.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Métricas de Uso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Resumen de la actividad del sistema',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Tarjetas de resumen
              _buildResumenGeneral(),

              const SizedBox(height: 32),

              // Gráfico de frecuencia de consultas
              _buildFrecuenciaConsultas(),

              const SizedBox(height: 32),

              // Exámenes por área
              _buildExamenesPorArea(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// ----------------------------------------------------------
  /// RESUMEN GENERAL CON TARJETAS
  /// ----------------------------------------------------------
  Widget _buildResumenGeneral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen General',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        const SizedBox(height: 16),

        // Fila 1: Exámenes y Consultas
        Row(
          children: [
            Expanded(
              child: _buildCardMetrica(
                titulo: 'Total Exámenes',
                stream: _firestoreService.streamTotalExamenes(),
                icon: Icons.science_outlined,
                color: AppStyles.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardMetrica(
                titulo: 'Total Consultas',
                stream: _firestoreService.streamTotalConsultas(),
                icon: Icons.search_outlined,
                color: AppStyles.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Fila 2: Usuarios totales y activos
        Row(
          children: [
            Expanded(
              child: _buildCardMetrica(
                titulo: 'Usuarios Totales',
                stream: _firestoreService.streamTotalUsuarios(),
                icon: Icons.people_outline,
                color: AppStyles.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCardMetrica(
                titulo: 'Activos (7 días)',
                stream: _firestoreService.streamUsuariosActivosUltimos7Dias(),
                icon: Icons.person_outline,
                color: AppStyles.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardMetrica({
    required String titulo,
    required Stream<int> stream,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(titulo, icon, color);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(titulo, icon);
        }

        final value = snapshot.data ?? 0;

        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard(String titulo, IconData icon, Color color) {
    return Container(
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
        children: [
          Icon(icon, color: color.withOpacity(0.3), size: 28),
          const SizedBox(height: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            titulo,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String titulo, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red, size: 28),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.red)),
          const Text('Error', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// ----------------------------------------------------------
  /// GRÁFICO DE FRECUENCIA DE CONSULTAS
  /// ----------------------------------------------------------
  Widget _buildFrecuenciaConsultas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frecuencia de Consultas por Examen',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Exámenes más consultados por los usuarios',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        StreamBuilder<Map<String, int>>(
          stream: _firestoreService.streamFrecuenciaConsultas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Center(
                  child: Text(
                    'Error al cargar métricas de consultas',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay consultas registradas aún',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Las consultas se registrarán cuando los usuarios vean detalles de exámenes',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final sortedEntries = data.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            // Tomar solo los top 10
            final topEntries = sortedEntries.take(10).toList();

            return Container(
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
                children: [
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (topEntries.first.value * 1.2).toDouble(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${topEntries[group.x.toInt()].key}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${rod.toY.toInt()} consultas',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= topEntries.length) {
                                  return const Text('');
                                }
                                final examen = topEntries[value.toInt()].key;
                                // Acortar nombre si es muy largo
                                final nombreCorto = examen.length > 12
                                    ? '${examen.substring(0, 12)}...'
                                    : examen;

                                return Transform.rotate(
                                  angle: -0.5, // Rotar 45 grados
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      right: 8,
                                    ),
                                    child: Text(
                                      nombreCorto,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                );
                              },
                              reservedSize:
                                  60, // Más espacio para textos rotados
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(topEntries.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: topEntries[index].value.toDouble(),
                                color: AppStyles.secondaryColor,
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: ${data.values.fold(0, (sum, count) => sum + count)} consultas',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// ----------------------------------------------------------
  /// EXÁMENES POR ÁREA
  /// ----------------------------------------------------------
  Widget _buildExamenesPorArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribución de Exámenes por Área',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.primaryDark,
          ),
        ),
        const SizedBox(height: 16),

        StreamBuilder<Map<String, int>>(
          stream: _firestoreService.streamExamenesPorArea(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No hay exámenes registrados',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final sortedEntries = data.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Container(
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
                children: sortedEntries.map((entry) {
                  final percentage =
                      data.values.fold(0, (sum, val) => sum + val) > 0
                      ? (entry.value /
                            data.values.fold(0, (sum, val) => sum + val) *
                            100)
                      : 0;

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: percentage / 100,
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
            );
          },
        ),
      ],
    );
  }
}
