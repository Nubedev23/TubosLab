import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../models/examen.dart';
import '../services/carrito_service.dart';

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
                onPressed: carritoService.limpiarCarrito,
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

          // Muestra la lista de exámenes
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: AppStyles.padding,
                  itemCount: examenes.length,
                  itemBuilder: (context, index) {
                    final examen = examenes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: AppStyles.cardShape,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppStyles.secondaryColor,
                          child: Text(
                            examen.tubo.substring(0, 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          examen.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tubo: ${examen.tubo} (${examen.anticoagulante})',
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
              // Botón de Confirmación/Procesar
              Padding(
                padding: AppStyles.padding.copyWith(bottom: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implementar la lógica para procesar el carrito (ej. enviar solicitud, imprimir etiquetas)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Funcionalidad de procesamiento pendiente. Carrito procesado lógicamente.',
                          ),
                        ),
                      );
                      carritoService.limpiarCarrito();
                    },
                    icon: const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Procesar Carrito (${examenes.length})',
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
