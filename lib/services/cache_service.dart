import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/examen.dart';

class CacheService {
  // Singleton
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Keys para el caché
  static const String _examenesKey = 'examenes_cache';
  static const String _lastUpdateKey = 'examenes_last_update';
  static const String _manualUrlKey = 'manual_url_cache';

  // Duración del caché (24 horas)
  static const Duration _cacheDuration = Duration(hours: 24);

  // ============================================
  // CACHÉ DE EXÁMENES
  // ============================================

  /// Guarda la lista de exámenes en caché
  Future<void> guardarExamenes(List<Examen> examenes) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir lista de exámenes a JSON
      final examenesJson = examenes.map((examen) {
        return {
          'id': examen.id,
          'nombre': examen.nombre,
          'nombre_normalizado': examen.nombre_normalizado,
          'descripcion': examen.descripcion,
          'tubo': examen.tubo,
          'anticoagulante': examen.anticoagulante,
          'volumen_ml': examen.volumen_ml,
          'area': examen.area,
        };
      }).toList();

      final jsonString = jsonEncode(examenesJson);
      await prefs.setString(_examenesKey, jsonString);

      // Guardar timestamp de la última actualización
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('Caché: ${examenes.length} exámenes guardados');
    } catch (e) {
      debugPrint('Error al guardar caché de exámenes: $e');
    }
  }

  /// Obtiene la lista de exámenes del caché
  Future<List<Examen>?> obtenerExamenes() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar si el caché ha expirado
      if (await _cacheExpirado()) {
        debugPrint('Caché: Expirado, se necesita actualización');
        return null;
      }

      final jsonString = prefs.getString(_examenesKey);
      if (jsonString == null) {
        debugPrint('Caché: No hay datos guardados');
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final examenes = jsonList.map((json) {
        return Examen(
          id: json['id'] as String?,
          nombre: json['nombre'] as String,
          nombre_normalizado: json['nombre_normalizado'] as String,
          descripcion: json['descripcion'] as String,
          tubo: json['tubo'] as String,
          anticoagulante: json['anticoagulante'] as String,
          volumen_ml: (json['volumen_ml'] as num).toDouble(),
          area: json['area'] as String?,
        );
      }).toList();

      debugPrint('Caché: ${examenes.length} exámenes recuperados');
      return examenes;
    } catch (e) {
      debugPrint('Error al obtener caché de exámenes: $e');
      return null;
    }
  }

  /// Verifica si el caché ha expirado
  Future<bool> _cacheExpirado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      if (lastUpdate == null) return true;

      final lastUpdateDate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(lastUpdateDate);

      return diferencia > _cacheDuration;
    } catch (e) {
      debugPrint('Error al verificar expiración de caché: $e');
      return true;
    }
  }

  /// Obtiene la fecha de la última actualización del caché
  Future<DateTime?> obtenerFechaUltimaActualizacion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);

      if (lastUpdate == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(lastUpdate);
    } catch (e) {
      debugPrint('Error al obtener fecha de última actualización: $e');
      return null;
    }
  }

  // ============================================
  // CACHÉ DE URL DEL MANUAL
  // ============================================

  /// Guarda la URL del manual en caché
  Future<void> guardarUrlManual(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_manualUrlKey, url);
      debugPrint('Caché: URL del manual guardada');
    } catch (e) {
      debugPrint('Error al guardar URL del manual: $e');
    }
  }

  /// Obtiene la URL del manual del caché
  Future<String?> obtenerUrlManual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString(_manualUrlKey);
      debugPrint('Caché: URL del manual recuperada');
      return url;
    } catch (e) {
      debugPrint('Error al obtener URL del manual: $e');
      return null;
    }
  }

  // ============================================
  // BÚSQUEDAS RECIENTES
  // ============================================

  static const String _busquedasRecientesKey = 'busquedas_recientes';
  static const int _maxBusquedasRecientes = 10;

  /// Guarda una búsqueda reciente
  Future<void> guardarBusquedaReciente(String termino) async {
    try {
      if (termino.trim().isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final busquedasJson = prefs.getString(_busquedasRecientesKey);

      List<String> busquedas = [];
      if (busquedasJson != null) {
        busquedas = List<String>.from(jsonDecode(busquedasJson));
      }

      // Remover si ya existe (para moverlo al principio)
      busquedas.remove(termino);

      // Agregar al principio
      busquedas.insert(0, termino);

      // Mantener solo las últimas N búsquedas
      if (busquedas.length > _maxBusquedasRecientes) {
        busquedas = busquedas.sublist(0, _maxBusquedasRecientes);
      }

      await prefs.setString(_busquedasRecientesKey, jsonEncode(busquedas));
      debugPrint('Caché: Búsqueda reciente guardada - "$termino"');
    } catch (e) {
      debugPrint('Error al guardar búsqueda reciente: $e');
    }
  }

  /// Obtiene la lista de búsquedas recientes
  Future<List<String>> obtenerBusquedasRecientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final busquedasJson = prefs.getString(_busquedasRecientesKey);

      if (busquedasJson == null) return [];

      return List<String>.from(jsonDecode(busquedasJson));
    } catch (e) {
      debugPrint('Error al obtener búsquedas recientes: $e');
      return [];
    }
  }

  /// Limpia las búsquedas recientes
  Future<void> limpiarBusquedasRecientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_busquedasRecientesKey);
      debugPrint('Caché: Búsquedas recientes eliminadas');
    } catch (e) {
      debugPrint('Error al limpiar búsquedas recientes: $e');
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  /// Limpia todo el caché
  Future<void> limpiarTodoElCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_examenesKey);
      await prefs.remove(_lastUpdateKey);
      await prefs.remove(_manualUrlKey);
      await prefs.remove(_busquedasRecientesKey);
      debugPrint('Caché: Todo el caché ha sido limpiado');
    } catch (e) {
      debugPrint('Error al limpiar todo el caché: $e');
    }
  }

  /// Obtiene el tamaño aproximado del caché en KB
  Future<double> obtenerTamanoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [_examenesKey, _manualUrlKey, _busquedasRecientesKey];

      int totalBytes = 0;
      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalBytes += value.length;
        }
      }

      return totalBytes / 1024; // Convertir a KB
    } catch (e) {
      debugPrint('Error al obtener tamaño del caché: $e');
      return 0.0;
    }
  }
}
