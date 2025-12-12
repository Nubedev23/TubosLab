import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/firestore_service.dart';
import '../models/examen.dart';
import '../services/history_service.dart';

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

  Widget _buildTuboCard(String tubo, String anticoagulante) {
    final tuboColor = AppStyles.getColorForTubo(tubo);
    final textColor = AppStyles.getTextColorForTubo(tubo);
    final lightColor = AppStyles.getLightColorForTubo(tubo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tuboColor, width: 2),
      ),
      child: Row(
        children: [
          // Ícono del tubo con color
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: tuboColor, shape: BoxShape.circle),
            child: Icon(Icons.science_outlined, color: textColor, size: 32),
          ),
          const SizedBox(width: 16),
          // Información del tubo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tubo $tubo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tuboColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  anticoagulante,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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
    final HistoryService historyService = HistoryService();

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
          // Guardar en el historial de consultas
          WidgetsBinding.instance.addPostFrameCallback((_) {
            historyService.guardarConsulta(examen);
          });

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
                const SizedBox(height: 8),
                // Descripción del Examen
                Text(
                  examen.descripcion,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                //card del tubo con color
                _buildTuboCard(examen.tubo, examen.anticoagulante),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text(
                  'Especificaciones del Examen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),

                _buildDetailRow(
                  Icons.monitor_weight_outlined,
                  'Volumen Mínimo',
                  '${examen.volumen_ml} ml',
                ),

                const Divider(height: 10),

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
