import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../models/examen.dart';
import '../services/carrito_service.dart';
// Importamos la pantalla de resumen con el nuevo nombre
import 'pantalla_resumen_examen.dart';

class PantallaCarrito extends StatelessWidget {
  const PantallaCarrito({super.key});

  static const routeName = '/carrito';

  @override
  Widget build(BuildContext context) {
    // Instancia del servicio de carrito
    final carritoService = CarritoService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Exámenes'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          // Botón para limpiar el carrito (solo si hay elementos)
          ValueListenableBuilder<List<Examen>>(
            valueListenable: carritoService.examenesEnCarritoListenable,
            builder: (context, examenes, child) {
              if (examenes.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Limpiar Carrito',
                onPressed: () {
                  // Usamos un modal o Snackbar para confirmar antes de limpiar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '¿Estás seguro de limpiar el carrito?',
                      ),
                      action: SnackBarAction(
                        label: 'SÍ',
                        textColor: Colors.redAccent,
                        onPressed: carritoService.limpiarCarrito,
                      ),
                      duration: const Duration(seconds: 3),
                    ),
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
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tu carrito está vacío.',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Agrega exámenes desde la búsqueda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 1. LISTA DETALLADA DE EXÁMENES SOLICITADOS
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
                    final tuboColor = AppStyles.getColorForTubo(examen.tubo);
                    final tuboTextColor = AppStyles.getTextColorForTubo(
                      examen.tubo,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 1,
                      shape: AppStyles.cardShape,
                      child: ListTile(
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          // Mantenemos el detalle de Área y Tubo
                          'Área: ${examen.area} | Tubo: ${examen.tubo} (${examen.anticoagulante})',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              carritoService.removerExamen(examen.id!),
                          tooltip: 'Quitar del carrito',
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 2. Botón de Confirmación/Procesar
              Padding(
                padding: AppStyles.padding.copyWith(bottom: 20, top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // **LÓGICA DE NAVEGACIÓN:**
                      // Al presionar, navegamos a la pantalla de resumen.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const PantallaResumenExamen(), // ¡Nombre actualizado!
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white,
                    ),
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
