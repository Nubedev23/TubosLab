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
  final String _queriesCollection = 'exam_queries';

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

  User? get currentUser => _auth.currentUser;

  // control de rol (admin)
  Future<bool> esAdmin(String uid) async {
    final doc = await _db.collection(_usersCollection).doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
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
  /// STREAM DE BÚSQUEDA (CON CACHÉ LOCAL Y FILTRO POR ÁREA)
  /// ----------------------------------------------------------
  Stream<List<Examen>> streamExamenesBusqueda(
    String query,
    String? area,
  ) async* {
    final normalized = normalizar(query);

    if (normalized.isEmpty && area == null) {
      yield* streamExamenes();
      return;
    }

    try {
      if (normalized.isEmpty && area != null) {
        yield* _db
            .collection(_examenesCollection)
            .orderBy('nombre')
            .snapshots()
            .map((snapshot) {
              var examenes = snapshot.docs
                  .map((doc) => Examen.fromMap(doc.data(), doc.id))
                  .toList();

              examenes = examenes.where((examen) {
                final areaExamen = examen.area?.toLowerCase().trim() ?? '';
                final areaFiltro = area.toLowerCase().trim();
                return areaExamen == areaFiltro;
              }).toList();

              return examenes;
            });
        return;
      }

      yield* _db
          .collection(_examenesCollection)
          .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
          .where('nombre_normalizado', isLessThan: '${normalized}\uf8ff')
          .snapshots()
          .map((snapshot) {
            var examenes = snapshot.docs
                .map((doc) => Examen.fromMap(doc.data(), doc.id))
                .toList();

            if (normalized.isNotEmpty) {
              examenes = examenes.where((examen) {
                return examen.nombre_normalizado.contains(normalized);
              }).toList();
            }

            if (area != null && area.isNotEmpty) {
              examenes = examenes.where((examen) {
                final areaExamen = examen.area?.toLowerCase().trim() ?? '';
                final areaFiltro = area.toLowerCase().trim();
                return areaExamen == areaFiltro;
              }).toList();
            }

            return examenes;
          });
    } catch (e) {
      debugPrint('Error en búsqueda, usando caché: $e');

      final cachedExamenes = await _cacheService.obtenerExamenes();
      if (cachedExamenes != null) {
        var resultados = cachedExamenes;

        if (normalized.isNotEmpty) {
          resultados = resultados
              .where((e) => e.nombre_normalizado.contains(normalized))
              .toList();
        }

        if (area != null && area.isNotEmpty) {
          resultados = resultados.where((e) {
            final areaExamen = e.area?.toLowerCase().trim() ?? '';
            final areaFiltro = area.toLowerCase().trim();
            return areaExamen == areaFiltro;
          }).toList();
        }

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

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - REGISTRAR CONSULTA DE EXAMEN
  /// ----------------------------------------------------------
  Future<void> registrarConsultaExamen(String examenNombre) async {
    try {
      await _db.collection(_queriesCollection).add({
        'examenNombre': examenNombre,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonimo',
      });
    } catch (e) {
      debugPrint('Error al registrar consulta: $e');
    }
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - FRECUENCIA DE CONSULTAS
  /// ----------------------------------------------------------
  Stream<Map<String, int>> streamFrecuenciaConsultas() {
    return _db.collection(_queriesCollection).snapshots().map((snapshot) {
      Map<String, int> frecuencias = {};
      for (var doc in snapshot.docs) {
        String nombre = doc['examenNombre'] ?? 'Desconocido';
        frecuencias[nombre] = (frecuencias[nombre] ?? 0) + 1;
      }
      return frecuencias;
    });
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - TOTAL DE USUARIOS
  /// ----------------------------------------------------------
  Stream<int> streamTotalUsuarios() {
    return _db.collection(_usersCollection).snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - USUARIOS ACTIVOS ÚLTIMOS 7 DÍAS
  /// ----------------------------------------------------------
  Stream<int> streamUsuariosActivosUltimos7Dias() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return _db.collection(_usersCollection).snapshots().map((snapshot) {
      int activos = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastActive = data['last_active'] as Timestamp?;

        if (lastActive != null) {
          final lastActiveDate = lastActive.toDate();
          if (lastActiveDate.isAfter(sevenDaysAgo)) {
            activos++;
          }
        }
      }
      return activos;
    });
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - TOTAL DE EXÁMENES
  /// ----------------------------------------------------------
  Stream<int> streamTotalExamenes() {
    return _db.collection(_examenesCollection).snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - EXÁMENES POR ÁREA
  /// ----------------------------------------------------------
  Stream<Map<String, int>> streamExamenesPorArea() {
    return _db.collection(_examenesCollection).snapshots().map((snapshot) {
      Map<String, int> areaCount = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final area = data['area'] as String? ?? 'Sin área';
        areaCount[area] = (areaCount[area] ?? 0) + 1;
      }
      return areaCount;
    });
  }

  /// ----------------------------------------------------------
  /// ESTADÍSTICAS - TOTAL DE CONSULTAS
  /// ----------------------------------------------------------
  Stream<int> streamTotalConsultas() {
    return _db.collection(_queriesCollection).snapshots().map((snapshot) {
      return snapshot.docs.length;
    });
  }
}
