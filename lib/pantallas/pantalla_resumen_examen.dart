import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/carrito_service.dart';
import '../services/cache_service.dart';
import '../services/auth_service.dart';
import '../models/examen.dart';

class PantallaResumenExamen extends StatelessWidget {
  const PantallaResumenExamen({super.key});

  @override
  Widget build(BuildContext context) {
    final carritoService = CarritoService();
    final cacheService = CacheService();
    final authService = AuthService();

    // final resumenTubos = carritoService.obtenerResumenPorTubo();

    // Widget auxiliar para mostrar cada tubo agrupado
    Widget buildResumenTubo(ResumenTubo resumen) {
      // Usamos el color principal del tubo (que está en la primera letra del nombre)
      //
      final tuboCompleto = resumen.tubo;
      String nombreTubo;
      if (tuboCompleto.contains(' - ')) {
        nombreTubo = tuboCompleto.split(' - ').last;
      } else {
        nombreTubo = tuboCompleto;
      }

      // Obtener colores del tubo
      final tuboColor = AppStyles.getColorForTubo(nombreTubo);
      final textColor = AppStyles.getTextColorForTubo(nombreTubo);
      final lightColor = AppStyles.getLightColorForTubo(nombreTubo);

      final tooltipText = 'Exámenes: \n- ${resumen.examenes.join('\n- ')}';

      return Tooltip(
        message: tooltipText,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: AppStyles.cardShape,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              // Borde con color del tubo
              border: Border.all(color: tuboColor, width: 2),
              // ondo suave con color del tubo
              color: lightColor,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              // CircleAvatar con color del tubo
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tuboColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tuboColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.science_outlined,
                    color: textColor,
                    size: 28,
                  ),
                ),
              ),
              title: Text(
                tuboCompleto, // Muestra "Área - Tubo" completo
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: tuboColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Anticoagulante: ${resumen.anticoagulante}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${resumen.examenes.length} examen${resumen.examenes.length > 1 ? 'es' : ''} en este tubo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: tuboColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: tuboColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'x ${resumen.cantidad}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Toma de Muestra'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<Examen>>(
        valueListenable: carritoService.examenesEnCarritoListenable,
        builder: (context, examenesEnCarrito, child) {
          final resumenTubos = carritoService.obtenerResumenPorTubo();
          return Column(
            children: [
              // Título y explicación
              Container(
                padding: AppStyles.padding.copyWith(top: 20, bottom: 16),
                decoration: BoxDecoration(
                  color: AppStyles.primaryLight.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: AppStyles.primaryDark.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppStyles.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Muestras requeridas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryDark,
                                ),
                              ),
                              Text(
                                '${resumenTubos.length} recipiente${resumenTubos.length > 1 ? 's' : ''} necesario${resumenTubos.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estos son los tubos necesarios para todos los exámenes seleccionados.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              // Lista de Tubos Agrupados
              Expanded(
                child: ListView.builder(
                  padding: AppStyles.padding.copyWith(top: 16),
                  itemCount: resumenTubos.length,
                  itemBuilder: (context, index) {
                    return buildResumenTubo(resumenTubos[index]);
                  },
                ),
              ),

              // Botón Final
              Container(
                padding: AppStyles.padding.copyWith(bottom: 20, top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // NUEVO: Solo guardar en historial si está autenticado
                      final userId = authService.getCurrentUserId();
                      final isAuthenticated =
                          userId != null && userId != 'anonimo';

                      if (isAuthenticated) {
                        // Guardar en historial solo si está logueado
                        final examenes = examenesEnCarrito
                            .map((e) => e.nombre)
                            .toList();

                        final tubos = resumenTubos
                            .map(
                              (r) => r.tubo.contains(' - ')
                                  ? r.tubo.split(' - ').last
                                  : r.tubo,
                            )
                            .toSet()
                            .toList();

                        await cacheService.guardarSolicitudEnHistorial(
                          cantidadExamenes: examenes.length,
                          cantidadTubos: resumenTubos.length,
                          examenes: examenes,
                          tubos: tubos,
                        );
                      }

                      // Limpiar carrito (para todos los usuarios)
                      carritoService.limpiarCarrito();

                      // Volver al inicio
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);

                        final mensaje = isAuthenticated
                            ? 'Solicitud procesada y guardada en el historial.'
                            : 'Solicitud procesada. Inicia sesión para guardar historial.';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(mensaje),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Confirmar y Finalizar',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: AppStyles.cardShape,
                      elevation: 4,
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
