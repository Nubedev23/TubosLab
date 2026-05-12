import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/examen.dart';
import '../services/auth_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _examenesKey = 'examenes_cache';
  static const String _lastUpdateKey = 'examenes_last_update';
  static const String _manualUrlKey = 'manual_url_cache';
  static const String _busquedasKey = 'busquedas_recientes';
  static const Duration _cacheDuration = Duration(hours: 24);
  static const int _maxBusquedas = 10;
  static const int _maxSolicitudes = 20;

  late SharedPreferences _prefs;

  Future<void> initalize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Exámenes ──────────────────────────────────────────────────────
  Future<void> guardarExamenes(List<Examen> examenes) async {
    try {
      final json = examenes.map((e) => {
        'id': e.id,
        'nombre': e.nombre,
        'nombre_normalizado': e.nombre_normalizado,
        'condicion_paciente': e.condicion_paciente,
        'muestra': e.muestra,
        'recipiente': e.recipiente,
        'conservacion_transporte': e.conservacion_transporte,
        'seccion': e.seccion,
        'plazo_entrega': e.plazo_entrega,
        'observaciones': e.observaciones,
        'area': e.area,
        'es_derivado': e.es_derivado,
        'disponible_urgencia': e.disponible_urgencia,
        'horario_disponibilidad': e.horario_disponibilidad,
      }).toList();
      await _prefs.setString(_examenesKey, jsonEncode(json));
      await _prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error guardando caché: $e');
    }
  }

  Future<List<Examen>?> obtenerExamenes() async {
    try {
      if (await _cacheExpirado()) return null;
      final jsonString = _prefs.getString(_examenesKey);
      if (jsonString == null) return null;
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((j) => Examen(
        id: j['id'] as String?,
        nombre: j['nombre'] as String? ?? '',
        nombre_normalizado: j['nombre_normalizado'] as String? ?? '',
        condicion_paciente: j['condicion_paciente'] as String? ?? '',
        muestra: j['muestra'] as String? ?? '',
        recipiente: j['recipiente'] as String? ?? '',
        conservacion_transporte: j['conservacion_transporte'] as String? ?? '',
        seccion: j['seccion'] as String? ?? '',
        plazo_entrega: j['plazo_entrega'] as String? ?? '',
        observaciones: j['observaciones'] as String? ?? '',
        area: j['area'] as String?,
        es_derivado: j['es_derivado'] as bool? ?? false,
        disponible_urgencia: j['disponible_urgencia'] as bool? ?? false,
        horario_disponibilidad: j['horario_disponibilidad'] as String? ??
            'Lunes a jueves 8:00–17:00, viernes 8:00–16:00',
      )).toList();
    } catch (e) {
      debugPrint('Error leyendo caché: $e');
      return null;
    }
  }

  Future<bool> _cacheExpirado() async {
    final last = _prefs.getInt(_lastUpdateKey);
    if (last == null) return true;
    return DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(last)) > _cacheDuration;
  }

  // ── Búsquedas recientes ───────────────────────────────────────────
  Future<void> guardarBusquedaReciente(String termino) async {
    try {
      if (termino.trim().isEmpty) return;
      final raw = _prefs.getString(_busquedasKey);
      List<String> lista = raw != null ? List<String>.from(jsonDecode(raw)) : [];
      lista.remove(termino);
      lista.insert(0, termino);
      if (lista.length > _maxBusquedas) lista = lista.sublist(0, _maxBusquedas);
      await _prefs.setString(_busquedasKey, jsonEncode(lista));
    } catch (e) {
      debugPrint('Error guardando búsqueda: $e');
    }
  }

  Future<List<String>> obtenerBusquedasRecientes() async {
    try {
      final raw = _prefs.getString(_busquedasKey);
      return raw != null ? List<String>.from(jsonDecode(raw)) : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> limpiarBusquedasRecientes() async {
    await _prefs.remove(_busquedasKey);
  }

  // ── URL Manual ────────────────────────────────────────────────────
  Future<void> guardarUrlManual(String url) async {
    await _prefs.setString(_manualUrlKey, url);
  }

  Future<String?> obtenerUrlManual() async {
    return _prefs.getString(_manualUrlKey);
  }

  // ── Historial solicitudes ─────────────────────────────────────────
  String _getSolicitudesKey(String userId) => 'solicitudes_historial_$userId';

  Future<void> guardarSolicitudEnHistorial({
    required int cantidadExamenes,
    required int cantidadTubos,
    required List<String> examenes,
    required List<String> tubos,
  }) async {
    try {
      final userId = AuthService().getCurrentUserId();
      if (userId == null) return;
      final key = _getSolicitudesKey(userId);
      final solicitud = {
        'timestamp': DateTime.now().toIso8601String(),
        'cantidadExamenes': cantidadExamenes,
        'cantidadTubos': cantidadTubos,
        'examenes': examenes,
        'tubos': tubos,
        'userId': userId,
      };
      final raw = _prefs.getString(key);
      List<dynamic> historial = raw != null ? jsonDecode(raw) : [];
      historial.insert(0, solicitud);
      if (historial.length > _maxSolicitudes) {
        historial = historial.sublist(0, _maxSolicitudes);
      }
      await _prefs.setString(key, jsonEncode(historial));
    } catch (e) {
      debugPrint('Error guardando solicitud: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialSolicitudes() async {
    try {
      final userId = AuthService().getCurrentUserId();
      if (userId == null) return [];
      final raw = _prefs.getString(_getSolicitudesKey(userId));
      if (raw == null) return [];
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  Future<void> limpiarTodoElCache() async {
    await _prefs.remove(_examenesKey);
    await _prefs.remove(_lastUpdateKey);
    await _prefs.remove(_manualUrlKey);
    await _prefs.remove(_busquedasKey);
  }
}
