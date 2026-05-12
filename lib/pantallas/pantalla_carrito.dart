import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../models/examen.dart';
import '../services/carrito_service.dart';
import 'pantalla_resumen_examen.dart';
import 'pantalla_detalle_examen.dart';

class PantallaCarrito extends StatelessWidget {
  const PantallaCarrito({super.key});

  static const routeName = '/carrito';

  @override
  Widget build(BuildContext context) {
    final carritoService = CarritoService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Exámenes'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          ValueListenableBuilder<List<Examen>>(
            valueListenable: carritoService.examenesEnCarritoListenable,
            builder: (context, examenes, child) {
              if (examenes.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpiar Carrito',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Limpiar Carrito'),
                        content: const Text(
                          '¿Estás seguro de que deseas eliminar todos los exámenes del carrito?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              carritoService.limpiarCarrito();
                              Navigator.of(dialogContext).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Carrito limpiado'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Limpiar'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Examen>>(
        valueListenable: carritoService.examenesEnCarritoListenable,
        builder: (context, examenes, child) {
          if (examenes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Tu carrito está vacío.',
                      style: TextStyle(fontSize: 20, color: Colors.grey)),
                  SizedBox(height: 10),
                  Text('Agrega exámenes desde la búsqueda.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: AppStyles.padding.copyWith(bottom: 10, top: 15),
                child: Text(
                  'Exámenes seleccionados: ${examenes.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.primaryDark,
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: AppStyles.padding.copyWith(top: 0),
                  itemCount: examenes.length,
                  itemBuilder: (context, index) {
                    final examen = examenes[index];

                    // ── Colores usando el recipiente completo (texto libre) ──
                    final color = AppStyles.getColorForRecipiente(examen.recipiente);
                    final textColor = AppStyles.getTextColorForRecipiente(examen.recipiente);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: AppStyles.cardShape,
                      child: ListTile(
                        // ── Tap → detalle del examen ──────────────────────
                        onTap: () async {
                          await Navigator.of(context).pushNamed(
                            PantallaDetalleExamen.routeName,
                            arguments: examen.id,
                          );
                          // Al volver, el carrito sigue intacto automáticamente
                        },

                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: examen.es_derivado
                              ? Icon(Icons.local_shipping_outlined,
                                  color: textColor, size: 18)
                              : Text(
                                  examen.recipienteCorto.isNotEmpty
                                      ? examen.recipienteCorto[0]
                                      : '?',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),

                        title: Text(
                          examen.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Badge de recipiente con color
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    examen.recipienteCorto,
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (examen.disponible_urgencia)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade600,
                                        borderRadius: BorderRadius.circular(10)),
                                    child: const Text('24/7',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    examen.area ?? (examen.es_derivado ? examen.seccion : 'General'),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Indicador de que es tappable + botón eliminar
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 18),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                final nombre = examen.nombre;
                                carritoService.removerExamen(examen.id!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$nombre removido del carrito'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Quitar del carrito',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: AppStyles.padding.copyWith(bottom: 20, top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PantallaResumenExamen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.local_shipping_outlined,
                        color: Colors.white),
                    label: Text(
                      'Procesar Solicitud (${examenes.length} Exámenes)',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
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