import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/examen.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'cache_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CacheService _cacheService = CacheService();

  final String _examenesCollection = 'examenes';
  final String _usersCollection = 'users';

  String normalizar(String texto) {
    const acentos = 'áéíóúÁÉÍÓÚ';
    const sinAcentos = 'aeiouaeiou';
    for (int i = 0; i < acentos.length; i++) {
      texto = texto.replaceAll(acentos[i], sinAcentos[i]);
    }
    return texto.toLowerCase().trim();
  }

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'anonimo';
  }

  /// ----------------------------------------------------------
  /// STREAM DE TODOS LOS EXÁMENES (CON CACHÉ)
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenes() {
    return _db
        .collection(_examenesCollection)
        .orderBy('nombre')
        .snapshots()
        .asyncMap((snapshot) async {
          // CORREGIDO: Orden de parámetros (map, id)
          final examenes = snapshot.docs
              .map((doc) => Examen.fromMap(doc.data(), doc.id))
              .toList();

          await _cacheService.guardarExamenes(examenes);

          return examenes;
        })
        .handleError((error) async {
          debugPrint('Error en stream, intentando caché: $error');
          final cachedExamenes = await _cacheService.obtenerExamenes();
          if (cachedExamenes != null && cachedExamenes.isNotEmpty) {
            debugPrint('Usando ${cachedExamenes.length} exámenes del caché');
            return cachedExamenes;
          }
          throw error;
        });
  }

  /// ----------------------------------------------------------
  /// OBTENER EXÁMENES CON CACHÉ
  /// ----------------------------------------------------------
  Future<List<Examen>> getExamenesConCache() async {
    try {
      final snapshot = await _db
          .collection(_examenesCollection)
          .orderBy('nombre')
          .get();

      // CORREGIDO: Orden de parámetros (map, id)
      final examenes = snapshot.docs
          .map((doc) => Examen.fromMap(doc.data(), doc.id))
          .toList();

      await _cacheService.guardarExamenes(examenes);

      debugPrint('Obtenidos ${examenes.length} exámenes del servidor');
      return examenes;
    } catch (e) {
      debugPrint('Error al obtener del servidor: $e');

      final cachedExamenes = await _cacheService.obtenerExamenes();
      if (cachedExamenes != null && cachedExamenes.isNotEmpty) {
        debugPrint('Usando ${cachedExamenes.length} exámenes del caché');
        return cachedExamenes;
      }

      throw Exception('No hay conexión y no hay datos en caché');
    }
  }

  /// ----------------------------------------------------------
  /// STREAM DE BÚSQUEDA (CON CACHÉ LOCAL)
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenesBusqueda(String query) async* {
    final normalized = normalizar(query);

    if (normalized.isEmpty) {
      yield* streamExamenes();
      return;
    }

    try {
      yield* _db
          .collection(_examenesCollection)
          .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
          .where('nombre_normalizado', isLessThan: '${normalized}\uf8ff')
          .snapshots()
          .map((snapshot) {
            // CORREGIDO: Orden de parámetros (map, id)
            return snapshot.docs
                .map((doc) => Examen.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      debugPrint('Error en búsqueda, usando caché: $e');

      final cachedExamenes = await _cacheService.obtenerExamenes();
      if (cachedExamenes != null) {
        final resultados = cachedExamenes.where((examen) {
          return examen.nombre_normalizado.contains(normalized);
        }).toList();

        yield resultados;
      } else {
        yield [];
      }
    }
  }

  /// ----------------------------------------------------------
  /// OBTENER UN EXAMEN POR ID (CON CACHÉ)
  /// ----------------------------------------------------------
  Future<Examen?> getExamen(String id) async {
    try {
      final doc = await _db.collection(_examenesCollection).doc(id).get();
      if (doc.exists) {
        // ✅ CORREGIDO: Orden de parámetros (map, id)
        return Examen.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener examen, buscando en caché: $e');

      final cachedExamenes = await _cacheService.obtenerExamenes();
      if (cachedExamenes != null) {
        try {
          return cachedExamenes.firstWhere((examen) => examen.id == id);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  /// ----------------------------------------------------------
  /// GUARDAR / ACTUALIZAR EXAMEN
  /// ----------------------------------------------------------
  Future<void> saveExamen(Examen examen) async {
    final Map<String, dynamic> data = examen.toMap();
    final String docId = examen.id ?? '';
    final bool isNew = docId.isEmpty;

    data['nombre_normalizado'] = normalizar(examen.nombre);
    data['ultima_actualizacion'] = FieldValue.serverTimestamp();
    data['updated_by'] = getCurrentUserId();

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
          .set(data, SetOptions(merge: true));
    }

    await _invalidarCache();
  }

  /// ----------------------------------------------------------
  /// ELIMINAR EXAMEN
  /// ----------------------------------------------------------
  Future<void> deleteExamen(String id) async {
    await _db.collection(_examenesCollection).doc(id).delete();
    await _invalidarCache();
  }

  /// Invalida el caché para forzar una recarga
  Future<void> _invalidarCache() async {
    try {
      final snapshot = await _db
          .collection(_examenesCollection)
          .orderBy('nombre')
          .get();

      // CORREGIDO: Orden de parámetros (map, id)
      final examenes = snapshot.docs
          .map((doc) => Examen.fromMap(doc.data(), doc.id))
          .toList();

      await _cacheService.guardarExamenes(examenes);
      debugPrint('Caché actualizado después de modificación');
    } catch (e) {
      debugPrint('Error al invalidar caché: $e');
    }
  }

  /// ----------------------------------------------------------
  /// BÚSQUEDA SIMPLE
  /// ----------------------------------------------------------
  Future<List<Examen>> searchExamenes(String query) async {
    final normalized = normalizar(query);

    final snapshot = await _db
        .collection(_examenesCollection)
        .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
        .where('nombre_normalizado', isLessThan: '${normalized}z')
        .get();

    // CORREGIDO: Orden de parámetros (map, id)
    return snapshot.docs
        .map((doc) => Examen.fromMap(doc.data(), doc.id))
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
