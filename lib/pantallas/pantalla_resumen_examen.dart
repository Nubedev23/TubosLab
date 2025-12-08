import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/carrito_service.dart';

class PantallaResumenExamen extends StatelessWidget {
  const PantallaResumenExamen({super.key});

  @override
  Widget build(BuildContext context) {
    final carritoService = CarritoService();
    // Obtenemos el resumen de tubos una sola vez al construir la pantalla
    final resumenTubos = carritoService.obtenerResumenPorTubo();

    // Widget auxiliar para mostrar cada tubo agrupado
    Widget buildResumenTubo(ResumenTubo resumen) {
      // Usamos el color principal del tubo (que está en la primera letra del nombre)
      final tuboLetter = resumen.tubo.substring(0, 1);
      final tooltipText = 'Exámenes: \n- ${resumen.examenes.join('\n- ')}';

      return Tooltip(
        message: tooltipText,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: AppStyles.cardShape,
          color: AppStyles.primaryLight.withOpacity(0.1),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppStyles.secondaryColor,
              child: Text(
                tuboLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              resumen.tubo, // Área - Tubo
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'Anticoagulante: ${resumen.anticoagulante}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppStyles.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x ${resumen.cantidad}', // Cantidad de tubos de este tipo (siempre 1 por tipo)
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
      body: Column(
        children: [
          // Título y explicación
          Padding(
            padding: AppStyles.padding.copyWith(top: 20, bottom: 10),
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
                const SizedBox(height: 5),
                Text(
                  'Este es el listado de los ${resumenTubos.length} recipientes necesarios para todos los exámenes seleccionados.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Lista de Tubos Agrupados (El Resumen Final)
          Expanded(
            child: ListView(
              padding: AppStyles.padding.copyWith(top: 0),
              children: resumenTubos.map(buildResumenTubo).toList(),
            ),
          ),

          // Botón Final (Limpia carrito y vuelve a inicio)
          Padding(
            padding: AppStyles.padding.copyWith(bottom: 20, top: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Lógica para finalizar la solicitud o imprimir
                  carritoService
                      .limpiarCarrito(); // Limpiamos el carrito al finalizar

                  // Volvemos a la pantalla principal o de inicio
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Solicitud procesada. Carrito limpiado y volviendo al inicio.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print_outlined, color: Colors.white),
                label: const Text(
                  'Confirmar y volver al inicio',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: AppStyles.cardShape,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
