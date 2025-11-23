import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/examen.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Colecciones
  final String _examenesCollection = 'examenes';
  final String _usersCollection = 'users';

  /// Normaliza texto: minúsculas + sin tildes + trim
  String normalizar(String texto) {
    const acentos = 'áéíóúÁÉÍÓÚ';
    const sinAcentos = 'aeiouaeiou';

    for (int i = 0; i < acentos.length; i++) {
      texto = texto.replaceAll(acentos[i], sinAcentos[i]);
    }
    return texto.toLowerCase().trim();
  }

  /// ----------------------------------------------------------
  /// STREAM DE TODOS LOS EXÁMENES
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenes() {
    return _db.collection(_examenesCollection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Examen.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// ----------------------------------------------------------
  /// STREAM DE BÚSQUEDA
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenesBusqueda(String query) {
    final normalized = normalizar(query);

    if (normalized.isEmpty) {
      return streamExamenes();
    }

    return _db
        .collection(_examenesCollection)
        .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
        .where(
          'nombre_normalizado',
          isLessThan: '${normalized}z',
        ) // <- corregido
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Examen.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// ----------------------------------------------------------
  /// OBTENER UN EXAMEN POR ID
  /// ----------------------------------------------------------
  Future<Examen?> getExamen(String id) async {
    final doc = await _db.collection(_examenesCollection).doc(id).get();
    if (doc.exists) {
      return Examen.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// ----------------------------------------------------------
  /// GUARDAR / ACTUALIZAR EXAMEN
  /// ----------------------------------------------------------
  Future<void> saveExamen(Examen examen) async {
    final String docId = examen.id.isEmpty
        ? _db.collection(_examenesCollection).doc().id
        : examen.id;

    await _db
        .collection(_examenesCollection)
        .doc(docId)
        .set(examen.toMap(), SetOptions(merge: true));
  }

  /// ----------------------------------------------------------
  /// ELIMINAR EXAMEN
  /// ----------------------------------------------------------
  Future<void> deleteExamen(String id) async {
    await _db.collection(_examenesCollection).doc(id).delete();
  }

  /// ----------------------------------------------------------
  /// BÚSQUEDA SIMPLE (NO USADA YA)
  /// ----------------------------------------------------------
  Future<List<Examen>> searchExamenes(String query) async {
    final normalized = normalizar(query);

    final snapshot = await _db
        .collection(_examenesCollection)
        .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
        .where('nombre_normalizado', isLessThan: '${normalized}z')
        .get();

    return snapshot.docs
        .map((doc) => Examen.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// ----------------------------------------------------------
  /// ROLES DE USUARIO
  /// ----------------------------------------------------------
  Future<void> setUserRole(String userId, String role) async {
    await _db.collection(_usersCollection).doc(userId).set({
      'role': role,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();

      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      print('Error al obtener rol: $e');
      if (e.code == 'permission-denied') {
        throw Exception(
          '[cloud_firestore/permission-denied] No tienes permisos.',
        );
      }
      return null;
    }
  }
}
