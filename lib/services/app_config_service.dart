import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nombre del documento donde guardaremos la URL
  // Usamos un solo documento 'app_config' con un ID fijo para guardar todas las configuraciones globales.
  final String _configDocId = 'manual';
  final String _collectionName = 'app_config';

  /// ----------------------------------------------------------
  /// URL DEL MANUAL PDF (STREAM)
  /// ----------------------------------------------------------

  // Escucha cambios en el documento y devuelve la URL del manual.
  Stream<String?> getManualUrlStream() {
    return _db.collection(_collectionName).doc(_configDocId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        // Devuelve el valor del campo 'pdf_url'
        return snapshot.data()!['pdf_url'] as String?;
      }
      return null;
    });
  }

  /// ----------------------------------------------------------
  /// ACTUALIZAR URL DEL MANUAL
  /// ----------------------------------------------------------

  // Guarda la URL en el campo 'pdf_url' del documento 'manual'
  Future<void> updateManualUrl(String url) async {
    // Aseguramos que la URL sea válida antes de guardar
    if (url.trim().isEmpty) {
      throw Exception('La URL no puede estar vacía.');
    }

    // Usamos 'set' con 'merge: true' para solo actualizar el campo 'pdf_url'
    await _db.collection(_collectionName).doc(_configDocId).set({
      'pdf_url': url.trim(),
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
