import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/query_history.dart';
import '../models/examen.dart';
import 'auth_service.dart';

class HistoryService {
  // Singleton
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final AuthService _authService = AuthService();

  static const String _historyKey = 'query_history';
  static const int _maxHistoryItems = 10;

  /// Guarda una consulta en el historial
  /// CORRECCIÓN: Solo guarda si NO es usuario anónimo
  Future<void> guardarConsulta(Examen examen) async {
    try {
      // Si es usuario anónimo, no guardar en el historial
      if (_authService.isAnonymous()) {
        debugPrint('Historial: Usuario anónimo, no se guarda consulta');
        return;
      }

      final userId = _authService.getCurrentUserId();

      final prefs = await SharedPreferences.getInstance();

      // Crear el registro de consulta
      final queryHistory = QueryHistory(
        examenId: examen.id ?? '',
        examenNombre: examen.nombre,
        tubo: examen.tubo,
        anticoagulante: examen.anticoagulante,
        timestamp: DateTime.now(),
        userId: userId,
      );

      // Obtener historial existente
      final historyJson = prefs.getString(_historyKey);
      List<QueryHistory> historial = [];

      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        historial = decoded.map((item) => QueryHistory.fromJson(item)).toList();
      }

      // Agregar nueva consulta al inicio
      historial.insert(0, queryHistory);

      // Mantener solo las últimas N consultas
      if (historial.length > _maxHistoryItems) {
        historial = historial.sublist(0, _maxHistoryItems);
      }

      // Guardar historial actualizado
      final updatedJson = json.encode(
        historial.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, updatedJson);

      debugPrint('Historial: Consulta guardada - "${examen.nombre}"');
    } catch (e) {
      debugPrint('Error al guardar consulta en historial: $e');
    }
  }

  /// Obtiene el historial completo de consultas
  Future<List<QueryHistory>> obtenerHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) {
        return [];
      }

      final List<dynamic> decoded = json.decode(historyJson);
      return decoded.map((item) => QueryHistory.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error al obtener historial: $e');
      return [];
    }
  }

  /// Obtiene el historial filtrado por usuario actual
  /// Devuelve lista vacía si es usuario anónimo
  Future<List<QueryHistory>> obtenerHistorialUsuario() async {
    try {
      //  Si es usuario anónimo, devolver lista vacía
      if (_authService.isAnonymous()) {
        debugPrint('Historial: Usuario anónimo, no hay historial disponible');
        return [];
      }

      final userId = _authService.getCurrentUserId();

      final historialCompleto = await obtenerHistorial();

      // Filtrar solo las consultas del usuario actual
      return historialCompleto
          .where((item) => item.userId == userId)
          .take(_maxHistoryItems)
          .toList();
    } catch (e) {
      debugPrint('Error al obtener historial de usuario: $e');
      return [];
    }
  }

  /// Obtiene estadísticas de exámenes más consultados
  /// Devuelve mapa vacío si es usuario anónimo
  Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      // Si es usuario anónimo, devolver mapa vacío
      if (_authService.isAnonymous()) {
        debugPrint('Estadísticas: Usuario anónimo, no hay estadísticas');
        return {};
      }

      final historial = await obtenerHistorialUsuario();
      final Map<String, int> stats = {};

      for (var query in historial) {
        stats[query.examenNombre] = (stats[query.examenNombre] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error al obtener estadísticas: $e');
      return {};
    }
  }

  /// Limpia el historial del usuario actual
  Future<void> limpiarHistorialUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Si es anónimo, limpiar todo
      if (_authService.isAnonymous()) {
        await prefs.remove(_historyKey);
        debugPrint('Historial: Limpiado (usuario anónimo)');
        return;
      }

      final userId = _authService.getCurrentUserId();

      // Obtener historial completo
      final historialCompleto = await obtenerHistorial();

      // Mantener solo las consultas de otros usuarios
      final historialFiltrado = historialCompleto
          .where((item) => item.userId != userId)
          .toList();

      if (historialFiltrado.isEmpty) {
        await prefs.remove(_historyKey);
      } else {
        final updatedJson = json.encode(
          historialFiltrado.map((item) => item.toJson()).toList(),
        );
        await prefs.setString(_historyKey, updatedJson);
      }

      debugPrint('Historial: Limpiado para usuario $userId');
    } catch (e) {
      debugPrint('Error al limpiar historial: $e');
    }
  }

  /// Obtiene el tamaño del historial en KB
  Future<double> obtenerTamanoHistorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null) return 0.0;

      return historyJson.length / 1024; // Convertir a KB
    } catch (e) {
      debugPrint('Error al obtener tamaño del historial: $e');
      return 0.0;
    }
  }
}
