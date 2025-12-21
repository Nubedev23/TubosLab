/// Configuración y Helpers para Tests
///
/// Este archivo contiene utilidades comunes para todos los tests

import 'package:flutter_test/flutter_test.dart';
import 'package:tubos_app/models/examen.dart';

/// Clase helper con datos de prueba
class TestData {
  /// Examen de prueba - Hemograma
  static Examen get hemograma => Examen(
    id: 'test_hemograma',
    nombre: 'Hemograma Completo',
    nombre_normalizado: 'hemograma completo',
    descripcion: 'Conteo completo de células sanguíneas',
    tubo: 'Lila',
    anticoagulante: 'EDTA K2',
    volumen_ml: 3.5,
    area: 'Hematología',
  );

  /// Examen de prueba - Glicemia
  static Examen get glicemia => Examen(
    id: 'test_glicemia',
    nombre: 'Glicemia',
    nombre_normalizado: 'glicemia',
    descripcion: 'Medición de glucosa en sangre',
    tubo: 'Gris',
    anticoagulante: 'Fluoruro de sodio',
    volumen_ml: 2.0,
    area: 'Bioquímica',
  );

  /// Examen de prueba - TP (Tiempo de Protrombina)
  static Examen get tiempoProtrombina => Examen(
    id: 'test_tp',
    nombre: 'Tiempo de Protrombina (TP)',
    nombre_normalizado: 'tiempo de protrombina (tp)',
    descripcion: 'Evaluación de la coagulación sanguínea',
    tubo: 'Celeste',
    anticoagulante: 'Citrato de sodio 3.2%',
    volumen_ml: 2.7,
    area: 'Coagulación',
  );

  /// Examen de prueba - Creatinina
  static Examen get creatinina => Examen(
    id: 'test_creatinina',
    nombre: 'Creatinina',
    nombre_normalizado: 'creatinina',
    descripcion: 'Evaluación de función renal',
    tubo: 'Rojo',
    anticoagulante: 'Sin Aditivo',
    volumen_ml: 3.0,
    area: 'Bioquímica',
  );

  /// Lista con múltiples exámenes de prueba
  static List<Examen> get examenesDePrueba => [
    hemograma,
    glicemia,
    tiempoProtrombina,
    creatinina,
  ];
}

/// Matcher personalizado para verificar exámenes
class ExamenMatcher extends Matcher {
  final String expectedNombre;
  final String? expectedTubo;

  ExamenMatcher(this.expectedNombre, {this.expectedTubo});

  @override
  bool matches(item, Map matchState) {
    if (item is! Examen) return false;

    if (item.nombre != expectedNombre) return false;
    if (expectedTubo != null && item.tubo != expectedTubo) return false;

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('Examen con nombre "$expectedNombre"');
  }
}

/// Helper para crear examen personalizado en tests
Examen crearExamenTest({
  String? id,
  String nombre = 'Test Examen',
  String tubo = 'Lila',
  String anticoagulante = 'EDTA K2',
  double volumen = 3.0,
  String? area,
}) {
  return Examen(
    id: id,
    nombre: nombre,
    nombre_normalizado: nombre.toLowerCase(),
    descripcion: 'Descripción de test para $nombre',
    tubo: tubo,
    anticoagulante: anticoagulante,
    volumen_ml: volumen,
    area: area ?? 'General',
  );
}

/// Configuración de timeouts para tests
class TestConfig {
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 15);
  static const Duration longTimeout = Duration(seconds: 30);
}

/// Helper para verificar que un Future se completa rápidamente
/// Útil para verificar CP sobre tiempo de respuesta < 2 segundos
Future<T> expectCompletesQuickly<T>(
  Future<T> future, {
  Duration maxDuration = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  final result = await future;
  stopwatch.stop();

  expect(
    stopwatch.elapsed,
    lessThan(maxDuration),
    reason:
        'Operación tardó ${stopwatch.elapsed.inMilliseconds}ms, '
        'esperado < ${maxDuration.inMilliseconds}ms',
  );

  return result;
}

/// Helper para verificar reglas de Firestore
class FirestoreRules {
  static const String anonymousUserId = 'anonymous_test';
  static const String userUserId = 'user_test_123';
  static const String adminUserId = 'admin_test_123';
}

/// Datos para tests de autenticación
class AuthTestData {
  static const String adminEmail = 'admin@test.com';
  static const String adminPassword = 'Test123456!';

  static const String userEmail = 'user@test.com';
  static const String userPassword = 'Test123456!';
}

/// Mock de respuesta de Firestore
class MockFirestoreResponse {
  final Map<String, dynamic> data;
  final String id;

  MockFirestoreResponse(this.data, this.id);

  Map<String, dynamic> toJson() => data;
}

/// Helper para simular delay de red
Future<void> simulateNetworkDelay([
  Duration duration = const Duration(milliseconds: 100),
]) {
  return Future.delayed(duration);
}
