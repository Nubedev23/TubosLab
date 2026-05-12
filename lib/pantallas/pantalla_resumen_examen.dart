import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/carrito_service.dart';
import '../services/cache_service.dart';
import '../services/auth_service.dart';
import '../models/examen.dart';

class PantallaResumenExamen extends StatelessWidget {
  const PantallaResumenExamen({super.key});

  Color _colorRecipiente(String recipiente) {
    final r = recipiente.toLowerCase();
    if (r.contains('tapa roja')) return const Color(0xFFE53935);
    if (r.contains('tapa lila') || r.contains('edta')) return const Color(0xFF9C27B0);
    if (r.contains('tapa celeste') || r.contains('citrato')) return const Color(0xFF03A9F4);
    if (r.contains('tapa verde') && r.contains('hormonas')) return const Color(0xFF2E7D32);
    if (r.contains('tapa verde') && r.contains('química')) return const Color(0xFF388E3C);
    if (r.contains('tapa verde')) return const Color(0xFF4CAF50);
    if (r.contains('tapa gris') || r.contains('fluoruro')) return const Color(0xFF757575);
    if (r.contains('frasco') && r.contains('estéril')) return const Color(0xFF0277BD);
    if (r.contains('frasco')) return const Color(0xFF0288D1);
    if (r.contains('papel filtro')) return const Color(0xFFFFA000);
    if (r.contains('portaobjeto') || r.contains('cinta')) return const Color(0xFF546E7A);
    if (r.contains('hisopo') || r.contains('tórula') || r.contains('torula')) {
      return const Color(0xFF00897B);
    }
    return AppStyles.primaryDark;
  }

  Widget _buildTarjetaInterna(ResumenRecipiente r) {
    final color = _colorRecipiente(r.recipiente);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: AppStyles.cardShape,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          border: Border.all(color: color, width: 2),
          color: color.withOpacity(0.08),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(Icons.science_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.titulo,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  if (r.subtitulo != r.titulo)
                    Text(r.subtitulo,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  ...r.examenes.map((nombre) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 6, color: color),
                            const SizedBox(width: 6),
                            Expanded(child: Text(nombre, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              child: const Text('×1',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaDerivada(ResumenRecipiente r) {
    final recipColor = _colorRecipiente(r.recipiente);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: AppStyles.cardShape,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          border: Border.all(color: Colors.orange, width: 2),
          color: const Color(0xFFFFF8E1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.seccion ?? r.titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                  child: Text('${r.examenes.length} exam.',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: recipColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: recipColor.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.science_outlined, size: 14, color: recipColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(r.subtitulo,
                        style: TextStyle(
                            fontSize: 12, color: recipColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...r.examenes.map((nombre) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(child: Text(nombre, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carritoService = CarritoService();
    final cacheService = CacheService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Toma de Muestra'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<Examen>>(
        valueListenable: carritoService.examenesEnCarritoListenable,
        builder: (context, examenesEnCarrito, _) {
          final resumen = carritoService.obtenerResumenPorRecipiente();
          final internos = resumen.where((r) => !r.esDeriivado).toList();
          final derivados = resumen.where((r) => r.esDeriivado).toList();

          return Column(
            children: [
              // Header
              Container(
                padding: AppStyles.padding.copyWith(top: 16, bottom: 12),
                decoration: BoxDecoration(
                  color: AppStyles.primaryLight.withOpacity(0.07),
                  border: Border(
                      bottom: BorderSide(
                          color: AppStyles.primaryDark.withOpacity(0.1), width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppStyles.primaryDark,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assignment_turned_in,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Muestras requeridas',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryDark)),
                          Text(
                            '${examenesEnCarrito.length} examen(es) → '
                            '${internos.length} recipiente(s) del lab'
                            '${derivados.isNotEmpty ? ' + ${derivados.length} grupo(s) derivado(s)' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista
              Expanded(
                child: ListView(
                  padding: AppStyles.padding.copyWith(top: 16),
                  children: [
                    if (internos.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.business, size: 15, color: AppStyles.primaryDark),
                          SizedBox(width: 6),
                          Text('Procesados en el Laboratorio',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryDark,
                                  fontSize: 13)),
                        ]),
                      ),
                      ...internos.map(_buildTarjetaInterna),
                    ],
                    if (internos.isNotEmpty && derivados.isNotEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider()),
                    if (derivados.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 15, color: Colors.orange),
                          SizedBox(width: 6),
                          Text('Exámenes Derivados a Otros Centros',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 13)),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Text(
                          'El recipiente indicado es el que se debe usar para la extracción, '
                          'aunque el examen se envíe a otro centro.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ...derivados.map(_buildTarjetaDerivada),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Botón confirmar
              Container(
                padding: AppStyles.padding.copyWith(bottom: 20, top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2))
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final userId = authService.getCurrentUserId();
                      final isAuth = userId != null && userId != 'anonimo';
                      if (isAuth) {
                        await cacheService.guardarSolicitudEnHistorial(
                          cantidadExamenes: examenesEnCarrito.length,
                          cantidadTubos: resumen.length,
                          examenes: examenesEnCarrito.map((e) => e.nombre).toList(),
                          tubos: resumen.map((r) => r.recipiente).toSet().toList(),
                        );
                      }
                      carritoService.limpiarCarrito();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(isAuth
                              ? 'Solicitud procesada y guardada en el historial.'
                              : 'Solicitud procesada. Inicia sesión para guardar historial.'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ));
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      'Confirmar (${examenesEnCarrito.length} exámenes)',
                      style: const TextStyle(fontSize: 17, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: AppStyles.cardShape,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
