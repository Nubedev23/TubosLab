import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/examen.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirestoreService {
  // 1. Patrón Singleton: Una sola instancia para toda la aplicación.
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Dependencia de Auth

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

  // Obtiene el ID del usuario actual para la trazabilidad (C8)
  String getCurrentUserId() {
    // Si no hay usuario logueado (p. ej., durante un inicio anónimo), usa 'anonimo'.
    return _auth.currentUser?.uid ?? 'anonimo';
  }

  /// ----------------------------------------------------------
  /// STREAM DE TODOS LOS EXÁMENES
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenes() {
    // Añadida la ordenación para que el panel admin se vea consistente
    return _db
        .collection(_examenesCollection)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
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
      // Si la búsqueda está vacía, devuelve todos los exámenes ordenados.
      return streamExamenes();
    }

    return _db
        .collection(_examenesCollection)
        .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
        // Usamos \uf8ff para un rango de búsqueda más amplio, incluyendo prefijos más largos.
        .where('nombre_normalizado', isLessThan: '${normalized}\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Examen.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// ----------------------------------------------------------
  /// OBTENER UN EXAMEN POR ID (RF-09)
  /// ----------------------------------------------------------
  Future<Examen?> getExamen(String id) async {
    final doc = await _db.collection(_examenesCollection).doc(id).get();
    if (doc.exists) {
      // Usamos el operador ! ya que verificamos doc.exists
      return Examen.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// ----------------------------------------------------------
  /// GUARDAR / ACTUALIZAR EXAMEN (RF-07, RF-09, C8)
  /// ----------------------------------------------------------
  Future<void> saveExamen(Examen examen) async {
    // 1. Prepara el mapa de datos base (solo datos de negocio)
    final Map<String, dynamic> data = examen.toMap();

    // 2. Determina el ID del documento
    // En tu modelo Examen, el ID es String y se maneja como un String vacío ("") para nuevo.
    final String docId =
        examen.id ??
        ''; // Usamos ?? '' si el id fuera null (aunque el modelo lo define como no-nullable, se mantiene la precaución)
    final bool isNew = docId.isEmpty;

    // 3. Inyecta la normalización del nombre (para la búsqueda)
    data['nombre_normalizado'] = normalizar(examen.nombre);

    // 4. Inyecta los campos de Auditoría (C8)
    data['ultima_actualizacion'] = FieldValue.serverTimestamp();
    data['updated_by'] = getCurrentUserId();

    // Si es nuevo, también agregar la fecha de creación.
    if (isNew) {
      data['fecha_creacion'] = FieldValue.serverTimestamp();
    }

    if (isNew) {
      debugPrint('Creando nuevo examen...');
      await _db.collection(_examenesCollection).add(data);
    } else {
      debugPrint('Actualizando examen con ID: ${examen.id}');
      await _db
          .collection(_examenesCollection)
          .doc(docId)
          // Usamos set con merge: true para asegurar que solo actualizamos los campos
          // proporcionados, manteniendo otros que puedan existir.
          .set(data, SetOptions(merge: true));
    }
  }

  /// ----------------------------------------------------------
  /// ELIMINAR EXAMEN (CORRECCIÓN DE REFERENCIA)
  /// ----------------------------------------------------------
  Future<void> deleteExamen(String id) async {
    // FIX: Usamos el parámetro 'id' de la función en lugar de la variable no definida 'examenId'
    await _db.collection(_examenesCollection).doc(id).delete();
  }

  /// ----------------------------------------------------------
  /// BÚSQUEDA SIMPLE (Se mantiene para referencia, aunque se usa Stream)
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
      // Usar debugPrint en lugar de print para mejor manejo en Flutter
      debugPrint('Error al obtener rol: $e');
      if (e.code == 'permission-denied') {
        throw Exception(
          '[cloud_firestore/permission-denied] No tienes permisos.',
        );
      }
      return null;
    }
  }
}
