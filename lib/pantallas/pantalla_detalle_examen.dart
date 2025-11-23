import 'package:flutter/material.dart';
import '../utils/app_styles.dart'; // Asegúrate de que esta ruta sea correcta
import '../services/firestore_service.dart'; // Asegúrate de que esta ruta sea correcta
import '../models/examen.dart'; // Asegúrate de que esta ruta sea correcta

class PantallaDetalleExamen extends StatelessWidget {
  const PantallaDetalleExamen({super.key});

  static const routeName = '/detalle-examen';

  // Widget para mostrar una fila de información con icono
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppStyles.primaryDark, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtener el ID del documento (ej: 'glicemia') que se pasa por la navegación
    final examenId = ModalRoute.of(context)!.settings.arguments as String;
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalles del Examen'),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      // 2. Usamos FutureBuilder para esperar los datos de Firestore
      body: FutureBuilder<Examen?>(
        // Llama al método para obtener el examen por su ID
        future: firestoreService.getExamen(examenId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Examen no encontrado o ID inválido.'),
            );
          }

          final examen = snapshot.data!;

          // 3. Mostrar los detalles una vez que el objeto Examen esté disponible
          return SingleChildScrollView(
            padding: AppStyles.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del Examen como título principal
                Text(
                  examen
                      .nombre, // Muestra el nombre con mayúsculas/minúsculas correctas
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryDark,
                  ),
                ),
                const SizedBox(height: 5),
                // Descripción del Examen
                Text(
                  examen.descripcion,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),

                // --- Sección de Tubo y Muestra ---
                _buildDetailRow(Icons.opacity, 'Tubo Requerido', examen.tubo),
                _buildDetailRow(
                  Icons.colorize,
                  'Anticoagulante',
                  examen.anticoagulante,
                ),
                _buildDetailRow(
                  Icons.monitor_weight_outlined,
                  'Volumen Mínimo',
                  '${examen.volumen_ml} ml',
                ),

                const Divider(height: 30),

                // --- Sección de Procesamiento y Área ---
                // _buildDetailRow(
                //   Icons.access_time_filled,
                //   'Tiempo de Proceso',
                //   examen.tiempo_proceso,
                // ),
                // // Aquí usamos el operador ?? para asegurar que si 'area' es null, se muestre un mensaje
                _buildDetailRow(
                  Icons.business_outlined,
                  'Área del Laboratorio',
                  examen.area ?? 'No especificada',
                ),

                const Divider(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}
