import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/examen.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Examen> _examenesRef;

  FirestoreService() {
    _examenesRef = _db
        .collection('examenes')
        .withConverter<Examen>(
          // Convierte de Map a objeto Examen
          fromFirestore: (snapshots, _) =>
              Examen.fromMap(snapshots.id, snapshots.data()!),
          // Convierte de objeto Examen a Map
          toFirestore: (examen, _) => examen.toMap(),
        );
  }

  // =========================================================================
  // OPERACIONES READ (Lectura y Búsqueda)
  // =========================================================================

  /// Obtiene un Stream de todos los exámenes.
  Stream<List<Examen>> getExamenesStream() {
    return _examenesRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  /// Obtiene un examen específico por su ID.
  Future<Examen?> getExamen(String id) async {
    final doc = await _examenesRef.doc(id).get();

    if (doc.exists && doc.data() != null) {
      return doc.data();
    }
    return null;
  }

  // =========================================================================
  // BÚSQUEDA
  // =========================================================================

  /// Busca exámenes por nombre, trayendo toda la colección y filtrando en el cliente.
  Future<List<Examen>> searchExamenes(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // 1. Obtener TODOS los documentos de la colección
    // Nota: Esta operación puede ser costosa si la colección es muy grande.
    final QuerySnapshot<Examen> snapshot = await _examenesRef.get();

    // Normalizamos la búsqueda a minúsculas para comparaciones insensibles a mayúsculas/minúsculas
    final String normalizedQuery = query.toLowerCase();

    // 2. FILTRAR los resultados en Flutter (case-insensitive)
    final List<Examen>
    resultados = snapshot.docs.map((doc) => doc.data()).where((examen) {
      // Normalizamos el nombre del examen de la DB a minúsculas
      final String examenNombreLower = examen.nombre.toLowerCase();

      // Verificamos si el nombre normalizado CONTIENE la consulta normalizada
      return examenNombreLower.contains(normalizedQuery);
    }).toList();

    return resultados;
  }

  // =========================================================================
  // OPERACIONES WRITE (Crear y Actualizar)
  // =========================================================================

  /// Guarda un nuevo examen o actualiza uno existente.
  Future<void> saveExamen(Examen examen) async {
    if (examen.id.isEmpty) {
      // Nuevo examen
      await _examenesRef.add(examen);
    } else {
      // Actualizar existente
      await _examenesRef.doc(examen.id).set(examen);
    }
  }

  /// Borra un examen por su ID.
  Future<void> deleteExamen(String id) async {
    await _examenesRef.doc(id).delete();
  }
}
