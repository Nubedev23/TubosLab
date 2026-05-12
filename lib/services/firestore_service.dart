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
  const mapa = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'ñ': 'n', 'Ñ': 'N',
  };

  final buffer = StringBuffer();

  for (int i = 0; i < texto.length; i++) {
    final char = texto[i];
    buffer.write(mapa[char] ?? char);
  }

  return buffer.toString().toLowerCase().trim();
}

  String getCurrentUserId() => _auth.currentUser?.uid ?? 'anonimo';
  User? get currentUser => _auth.currentUser;

  Future<bool> esAdmin(String uid) async {
    final doc = await _db.collection(_usersCollection).doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }

  // ── Stream principal de todos los exámenes ───────────────────────
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
          debugPrint('Error en streamExamenes, usando caché: $error');
          final cached = await _cacheService.obtenerExamenes();
          if (cached != null && cached.isNotEmpty) return cached;
          throw error;
        });
  }

  // ── Stream de búsqueda con filtros ───────────────────────────────
  Stream<List<Examen>> streamExamenesBusqueda(
    String query,
    String? area, {
    String? filtroTipo,
    bool soloUrgencia = false,
  }) {
    final normalized = normalizar(query);
    final bool sinTexto = normalized.isEmpty;
    final bool sinArea = area == null || area.isEmpty;
    final bool sinTipo = filtroTipo == null;
    final bool sinFiltros = sinTexto && sinArea && sinTipo && !soloUrgencia;

    if (sinFiltros) {
      return streamExamenes();
    }

    final Stream<List<Examen>> streamBase;

    if (!sinTexto) {
      streamBase = _db
          .collection(_examenesCollection)
          .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
          .where('nombre_normalizado', isLessThan: '$normalized\uf8ff')
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => Examen.fromMap(doc.data(), doc.id))
              .where((e) => e.nombre_normalizado.contains(normalized))
              .toList());
    } else {
      streamBase = _db
          .collection(_examenesCollection)
          .orderBy('nombre')
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => Examen.fromMap(doc.data(), doc.id)).toList());
    }

    return streamBase
        .map((examenes) => _aplicarFiltros(
              examenes,
              area: area,
              filtroTipo: filtroTipo,
              soloUrgencia: soloUrgencia,
              sinArea: sinArea,
            ))
        .handleError((error) async {
          debugPrint('Error en streamExamenesBusqueda, usando caché: $error');
          final cached = await _cacheService.obtenerExamenes();
          if (cached != null && cached.isNotEmpty) {
            return _aplicarFiltros(
              cached,
              area: area,
              filtroTipo: filtroTipo,
              soloUrgencia: soloUrgencia,
              sinArea: sinArea,
              queryNorm: normalized,
            );
          }
          return <Examen>[];
        });
  }

  // Aplica todos los filtros en memoria sobre una lista de exámenes
  List<Examen> _aplicarFiltros(
    List<Examen> examenes, {
    String? area,
    String? filtroTipo,
    bool soloUrgencia = false,
    bool sinArea = true,
    String queryNorm = '',
  }) {
    var r = examenes;

    if (queryNorm.isNotEmpty) {
      r = r.where((e) => e.nombre_normalizado.contains(queryNorm)).toList();
    }

    if (soloUrgencia) {
      r = r.where((e) => e.disponible_urgencia).toList();
    }

    if (filtroTipo == 'interno') {
      r = r.where((e) => !e.es_derivado).toList();
    } else if (filtroTipo == 'derivado') {
      r = r.where((e) => e.es_derivado).toList();
    }

    if (!sinArea && area != null) {
      final areaFiltro = area.toLowerCase().trim();
      r = r.where((e) => (e.area ?? '').toLowerCase().trim() == areaFiltro).toList();
    }

    return r;
  }

  // ── Obtener un examen por ID ─────────────────────────────────────
  Future<Examen?> getExamen(String id) async {
    try {
      final doc = await _db.collection(_examenesCollection).doc(id).get();
      if (doc.exists) return Examen.fromMap(doc.data()!, doc.id);
      return null;
    } catch (e) {
      debugPrint('Error getExamen, buscando en caché: $e');
      final cached = await _cacheService.obtenerExamenes();
      if (cached != null) {
        try {
          return cached.firstWhere((ex) => ex.id == id);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  // ── Guardar / actualizar examen ──────────────────────────────────
  Future<void> saveExamen(Examen examen) async {
    final data = examen.toMap();
    data['nombre_normalizado'] = normalizar(examen.nombre);
    data['ultima_actualizacion'] = FieldValue.serverTimestamp();
    data['updated_by'] = getCurrentUserId();

    final bool isNew = (examen.id == null || examen.id!.isEmpty);
    if (isNew) {
      data['fecha_creacion'] = FieldValue.serverTimestamp();
      await _db.collection(_examenesCollection).add(data);
    } else {
      await _db
          .collection(_examenesCollection)
          .doc(examen.id)
          .set(data, SetOptions(merge: true));
    }
    await _invalidarCache();
  }

  // ── Eliminar examen ──────────────────────────────────────────────
  Future<void> deleteExamen(String id) async {
    await _db.collection(_examenesCollection).doc(id).delete();
    await _invalidarCache();
  }

  Future<void> _invalidarCache() async {
    try {
      final snapshot =
          await _db.collection(_examenesCollection).orderBy('nombre').get();
      final examenes =
          snapshot.docs.map((doc) => Examen.fromMap(doc.data(), doc.id)).toList();
      await _cacheService.guardarExamenes(examenes);
    } catch (e) {
      debugPrint('Error invalidando caché: $e');
    }
  }

  // ── Búsqueda puntual (para sugerencias) ─────────────────────────
  Future<List<Examen>> searchExamenes(String query) async {
    final normalized = normalizar(query);
    try {
      final snapshot = await _db
          .collection(_examenesCollection)
          .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
          .where('nombre_normalizado', isLessThan: '${normalized}z')
          .get();
      return snapshot.docs
          .map((doc) => Examen.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error en searchExamenes, usando caché: $e');
      final cached = await _cacheService.obtenerExamenes();
      if (cached != null) {
        return cached
            .where((e) => e.nombre_normalizado.contains(normalized))
            .take(10)
            .toList();
      }
      return [];
    }
  }

  // ── Búsqueda filtrada puntual (reemplaza al StreamBuilder) ───────
  Future<List<Examen>> searchExamenesFiltrado(
    String query,
    String? area, {
    String? filtroTipo,
    bool soloUrgencia = false,
  }) async {
    final normalized = normalizar(query);
    final bool sinTexto = normalized.isEmpty;
    final bool sinArea = area == null || area.isEmpty;

    try {
      List<Examen> examenes;

      if (!sinTexto) {
        final snapshot = await _db
            .collection(_examenesCollection)
            .where('nombre_normalizado', isGreaterThanOrEqualTo: normalized)
            .where('nombre_normalizado', isLessThan: '$normalized\uf8ff')
            .get();
        examenes = snapshot.docs
            .map((doc) => Examen.fromMap(doc.data(), doc.id))
            .where((e) => e.nombre_normalizado.contains(normalized))
            .toList();
      } else {
        // Sin texto pero con filtros (ej: solo urgencia, solo derivados)
        examenes = await getExamenesConCache();
      }

      return _aplicarFiltros(
        examenes,
        area: area,
        filtroTipo: filtroTipo,
        soloUrgencia: soloUrgencia,
        sinArea: sinArea,
      );
    } catch (e) {
      debugPrint('Error en searchExamenesFiltrado, usando caché: $e');
      final cached = await _cacheService.obtenerExamenes();
      if (cached != null && cached.isNotEmpty) {
        return _aplicarFiltros(
          cached,
          area: area,
          filtroTipo: filtroTipo,
          soloUrgencia: soloUrgencia,
          sinArea: sinArea,
          queryNorm: normalized,
        );
      }
      return [];
    }
  }

  // ── Roles ────────────────────────────────────────────────────────
  Future<void> setUserRole(String userId, String role) async {
    await _db.collection(_usersCollection).doc(userId).set(
        {'role': role, 'last_updated': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _db.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data?['role'] as String?;
    } catch (e) {
      debugPrint('Error al obtener rol: $e');
      return null;
    }
  }

  // ── Estadísticas ─────────────────────────────────────────────────
  Future<void> registrarConsultaExamen(String examenNombre) async {
    try {
      await _db.collection(_queriesCollection).add({
        'examenNombre': examenNombre,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid ?? 'anonimo',
      });
    } catch (e) {
      debugPrint('Error registrando consulta: $e');
    }
  }

  Stream<Map<String, int>> streamFrecuenciaConsultas() {
    return _db.collection(_queriesCollection).snapshots().map((snap) {
      final Map<String, int> freq = {};
      for (var doc in snap.docs) {
        final nombre = doc['examenNombre'] as String? ?? 'Desconocido';
        freq[nombre] = (freq[nombre] ?? 0) + 1;
      }
      return freq;
    });
  }

  Stream<int> streamTotalUsuarios() =>
      _db.collection(_usersCollection).snapshots().map((s) => s.docs.length);

  Stream<int> streamUsuariosActivosUltimos7Dias() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _db.collection(_usersCollection).snapshots().map((snap) {
      int activos = 0;
      for (var doc in snap.docs) {
        final ts = doc.data()['last_active'] as Timestamp?;
        if (ts != null && ts.toDate().isAfter(cutoff)) activos++;
      }
      return activos;
    });
  }

  Stream<int> streamTotalExamenes() =>
      _db.collection(_examenesCollection).snapshots().map((s) => s.docs.length);

  Stream<int> streamTotalConsultas() =>
      _db.collection(_queriesCollection).snapshots().map((s) => s.docs.length);

  Stream<Map<String, int>> streamExamenesPorArea() {
    return _db.collection(_examenesCollection).snapshots().map((snap) {
      final Map<String, int> areas = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        final esDer = data['es_derivado'] as bool? ?? false;
        if (esDer) {
          final sec = data['seccion'] as String? ?? 'Derivado';
          areas['Derivado: $sec'] = (areas['Derivado: $sec'] ?? 0) + 1;
        } else {
          final area = data['area'] as String? ?? 'Sin área';
          areas[area] = (areas[area] ?? 0) + 1;
        }
      }
      return areas;
    });
  }

  Future<List<Examen>> getExamenesConCache() async {
    try {
      final snapshot =
          await _db.collection(_examenesCollection).orderBy('nombre').get();
      final examenes =
          snapshot.docs.map((doc) => Examen.fromMap(doc.data(), doc.id)).toList();
      await _cacheService.guardarExamenes(examenes);
      return examenes;
    } catch (e) {
      final cached = await _cacheService.obtenerExamenes();
      if (cached != null && cached.isNotEmpty) return cached;
      throw Exception('Sin conexión y sin datos en caché');
    }
  }
}