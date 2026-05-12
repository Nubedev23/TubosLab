import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';
import '../services/history_service.dart';

class PantallaDetalleExamen extends StatelessWidget {
  const PantallaDetalleExamen({super.key});
  static const routeName = '/detalle-examen';

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppStyles.primaryDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipienteCard(Examen examen) {
    final r = examen.recipiente.toLowerCase();
    Color cardColor;
    IconData icono;

    if (r.contains('tapa roja')) { cardColor = const Color(0xFFE53935); icono = Icons.science; }
    else if (r.contains('tapa lila') || r.contains('edta')) { cardColor = const Color(0xFF9C27B0); icono = Icons.science; }
    else if (r.contains('tapa celeste') || r.contains('citrato')) { cardColor = const Color(0xFF03A9F4); icono = Icons.science; }
    else if (r.contains('tapa verde') && r.contains('hormonas')) { cardColor = const Color(0xFF2E7D32); icono = Icons.science; }
    else if (r.contains('tapa verde')) { cardColor = const Color(0xFF4CAF50); icono = Icons.science; }
    else if (r.contains('tapa gris') || r.contains('fluoruro')) { cardColor = const Color(0xFF757575); icono = Icons.science; }
    else if (r.contains('frasco') && r.contains('estéril')) { cardColor = const Color(0xFF0277BD); icono = Icons.water_drop_outlined; }
    else if (r.contains('frasco')) { cardColor = const Color(0xFF0288D1); icono = Icons.water_drop_outlined; }
    else if (r.contains('papel filtro')) { cardColor = const Color(0xFFFFA000); icono = Icons.filter_alt_outlined; }
    else if (r.contains('portaobjeto') || r.contains('cinta')) { cardColor = const Color(0xFF546E7A); icono = Icons.rectangle_outlined; }
    else if (r.contains('hisopo') || r.contains('tórula') || r.contains('torula')) { cardColor = const Color(0xFF00897B); icono = Icons.straighten; }
    else { cardColor = AppStyles.primaryDark; icono = Icons.inventory_2_outlined; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: Icon(icono, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recipiente',
                    style: TextStyle(
                        fontSize: 12,
                        color: cardColor,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(examen.recipiente,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cardColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bloque de disponibilidad horaria
  Widget _buildDisponibilidadCard(Examen examen) {
    final disponibleAhora = examen.estaDisponibleAhora();

    if (examen.disponible_urgencia) {
      // Urgencia: siempre verde
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disponible ahora',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                          fontSize: 14)),
                  Text(examen.horario_disponibilidad,
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('URGENCIA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Rutina: verde si está en horario, naranja si no
    final color = disponibleAhora ? Colors.green : Colors.orange;
    final icono = disponibleAhora
        ? Icons.check_circle_outline
        : Icons.access_time_filled;
    final titulo = disponibleAhora ? 'Disponible ahora' : 'No disponible en este momento';
    final subtitulo = disponibleAhora
        ? 'Se realiza en horario de rutina'
        : 'Este examen solo se realiza en horario de rutina';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color.shade800,
                            fontSize: 14)),
                    Text(subtitulo,
                        style: TextStyle(
                            color: color.shade700, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Horario detallado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 14, color: color.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    examen.horario_disponibilidad,
                    style: TextStyle(
                        fontSize: 13,
                        color: color.shade800,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDerivadoBadge(Examen examen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Examen Derivado',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 13)),
                Text('Se envía a: ${examen.seccion}',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examenId = ModalRoute.of(context)!.settings.arguments as String;
    final firestoreService = FirestoreService();
    final historyService = HistoryService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalle del Examen'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Examen?>(
        future: firestoreService.getExamen(examenId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Examen no encontrado.'));
          }

          final examen = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            historyService.guardarConsulta(examen);
            firestoreService.registrarConsultaExamen(examen.nombre);
          });

          return SingleChildScrollView(
            padding: AppStyles.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(examen.nombre,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryDark)),
                const SizedBox(height: 10),

                // Badge derivado
                if (examen.es_derivado) ...[
                  _buildDerivadoBadge(examen),
                  const SizedBox(height: 8),
                ],

                // Badge área interna
                if (!examen.es_derivado && examen.area != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business_outlined,
                            size: 16, color: AppStyles.primaryDark),
                        const SizedBox(width: 6),
                        Text(examen.area!,
                            style: const TextStyle(
                                color: AppStyles.primaryDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // ── DISPONIBILIDAD HORARIA (lo más visible) ──
                _buildDisponibilidadCard(examen),
                const SizedBox(height: 18),

                // Recipiente
                _buildRecipienteCard(examen),
                const SizedBox(height: 18),

                // Condiciones de la muestra
                const Text('Condiciones de la muestra',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryDark)),
                const Divider(),
                _buildDetailRow(Icons.person_outline,
                    'Condición del paciente', examen.condicion_paciente),
                _buildDetailRow(Icons.colorize_outlined,
                    'Muestra requerida', examen.muestra),
                _buildDetailRow(Icons.thermostat_outlined,
                    'Conservación y transporte', examen.conservacion_transporte),

                const SizedBox(height: 14),
                const Text('Información adicional',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.primaryDark)),
                const Divider(),
                _buildDetailRow(Icons.access_time_outlined,
                    'Plazo de entrega de resultados', examen.plazo_entrega),
                if (!examen.es_derivado)
                  _buildDetailRow(Icons.location_on_outlined,
                      'Sección de análisis', examen.seccion),

                // Observaciones
                if (examen.observaciones.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Observaciones',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(examen.observaciones,
                                    style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
