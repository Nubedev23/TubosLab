import 'package:flutter_test/flutter_test.dart';
import 'package:tubos_app/services/carrito_service.dart';
import 'package:tubos_app/models/examen.dart';

void main() {
  group('CarritoService - Pruebas Unitarias', () {
    late CarritoService carritoService;

    setUp(() {
      carritoService = CarritoService();
      carritoService.limpiarCarrito(); // Limpiar antes de cada test
    });

    tearDown(() {
      carritoService.limpiarCarrito(); // Limpiar después de cada test
    });

    group('Agregar Exámenes al Carrito', () {
      test('Debe agregar un examen al carrito vacío', () {
        // Arrange
        final examen = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');

        // Act
        carritoService.agregarExamen(examen);

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 1);
        expect(carritoService.estaEnCarrito('1'), true);
      });

      test('Debe agregar múltiples exámenes diferentes', () {
        // Arrange
        final examen1 = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');
        final examen2 = _crearExamenPrueba('2', 'Hemograma', 'Lila', 'EDTA K2');

        // Act
        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 2);
        expect(carritoService.estaEnCarrito('1'), true);
        expect(carritoService.estaEnCarrito('2'), true);
      });

      test('NO debe agregar el mismo examen dos veces', () {
        // Arrange
        final examen = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');

        // Act
        carritoService.agregarExamen(examen);
        carritoService.agregarExamen(examen); // Intentar agregar duplicado

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 1);
      });
    });

    group('Remover Exámenes del Carrito', () {
      test('Debe remover un examen existente', () {
        // Arrange
        final examen = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');
        carritoService.agregarExamen(examen);

        // Act
        carritoService.removerExamen('1');

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 0);
        expect(carritoService.estaEnCarrito('1'), false);
      });

      test('Debe remover solo el examen especificado', () {
        // Arrange
        final examen1 = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');
        final examen2 = _crearExamenPrueba('2', 'Hemograma', 'Lila', 'EDTA K2');
        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Act
        carritoService.removerExamen('1');

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 1);
        expect(carritoService.estaEnCarrito('1'), false);
        expect(carritoService.estaEnCarrito('2'), true);
      });

      test('No debe causar error al remover examen inexistente', () {
        // Act & Assert
        expect(
          () => carritoService.removerExamen('id_inexistente'),
          returnsNormally,
        );
      });
    });

    group('Limpiar Carrito', () {
      test('Debe eliminar todos los exámenes', () {
        // Arrange
        final examen1 = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');
        final examen2 = _crearExamenPrueba('2', 'Hemograma', 'Lila', 'EDTA K2');
        final examen3 = _crearExamenPrueba(
          '3',
          'Creatinina',
          'Rojo',
          'Sin Aditivo',
        );

        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);
        carritoService.agregarExamen(examen3);

        // Act
        carritoService.limpiarCarrito();

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 0);
        expect(carritoService.estaEnCarrito('1'), false);
        expect(carritoService.estaEnCarrito('2'), false);
        expect(carritoService.estaEnCarrito('3'), false);
      });

      test('Carrito vacío debe permanecer vacío', () {
        // Act
        carritoService.limpiarCarrito();

        // Assert
        expect(carritoService.examenesEnCarritoListenable.value.length, 0);
      });
    });

    group('Resumen por Tubo', () {
      test('Debe agrupar exámenes con el mismo tubo y anticoagulante', () {
        // Arrange
        final examen1 = _crearExamenPrueba(
          '1',
          'Glicemia',
          'Gris',
          'Fluoruro',
          area: 'Bioquímica',
        );
        final examen2 = _crearExamenPrueba(
          '2',
          'Glucosa PP',
          'Gris',
          'Fluoruro',
          area: 'Bioquímica',
        );

        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Act
        final resumen = carritoService.obtenerResumenPorTubo();

        // Assert
        expect(resumen.length, 1);
        expect(resumen[0].tubo, contains('Gris'));
        expect(resumen[0].anticoagulante, 'Fluoruro');
        expect(resumen[0].cantidad, 1);
        expect(resumen[0].examenes.length, 2);
      });

      test('Debe separar tubos diferentes aunque sean del mismo tipo', () {
        // Arrange - Mismo tubo pero diferentes anticoagulantes
        final examen1 = _crearExamenPrueba(
          '1',
          'Hemograma',
          'Lila',
          'EDTA K2',
          area: 'Hematología',
        );
        final examen2 = _crearExamenPrueba(
          '2',
          'TP',
          'Celeste',
          'Citrato',
          area: 'Coagulación',
        );

        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Act
        final resumen = carritoService.obtenerResumenPorTubo();

        // Assert
        expect(resumen.length, 2);
      });

      test('Debe separar por área aunque tengan mismo tubo', () {
        // Arrange
        final examen1 = _crearExamenPrueba(
          '1',
          'Hemograma',
          'Lila',
          'EDTA K2',
          area: 'Hematología',
        );
        final examen2 = _crearExamenPrueba(
          '2',
          'Otro Test',
          'Lila',
          'EDTA K2',
          area: 'Inmunología',
        );

        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Act
        final resumen = carritoService.obtenerResumenPorTubo();

        // Assert
        expect(resumen.length, 2);
      });

      test('Resumen debe incluir nombres de exámenes', () {
        // Arrange
        final examen1 = _crearExamenPrueba(
          '1',
          'Glicemia',
          'Gris',
          'Fluoruro',
          area: 'Bioquímica',
        );
        final examen2 = _crearExamenPrueba(
          '2',
          'Glucosa PP',
          'Gris',
          'Fluoruro',
          area: 'Bioquímica',
        );

        carritoService.agregarExamen(examen1);
        carritoService.agregarExamen(examen2);

        // Act
        final resumen = carritoService.obtenerResumenPorTubo();

        // Assert
        expect(resumen[0].examenes, contains('Glicemia'));
        expect(resumen[0].examenes, contains('Glucosa PP'));
      });

      test('Carrito vacío debe retornar resumen vacío', () {
        // Act
        final resumen = carritoService.obtenerResumenPorTubo();

        // Assert
        expect(resumen.length, 0);
      });
    });

    group('Verificar Estado del Carrito', () {
      test('estaEnCarrito debe retornar true para examen agregado', () {
        // Arrange
        final examen = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');
        carritoService.agregarExamen(examen);

        // Act & Assert
        expect(carritoService.estaEnCarrito('1'), true);
      });

      test('estaEnCarrito debe retornar false para examen no agregado', () {
        // Act & Assert
        expect(carritoService.estaEnCarrito('999'), false);
      });

      test('ValueNotifier debe notificar cambios al agregar', () {
        // Arrange
        var notified = false;
        carritoService.examenesEnCarritoListenable.addListener(() {
          notified = true;
        });

        final examen = _crearExamenPrueba('1', 'Glicemia', 'Gris', 'Fluoruro');

        // Act
        carritoService.agregarExamen(examen);

        // Assert
        expect(notified, true);
      });
    });
  });
}

// Helper function para crear exámenes de prueba
Examen _crearExamenPrueba(
  String id,
  String nombre,
  String tubo,
  String anticoagulante, {
  String? area,
}) {
  return Examen(
    id: id,
    nombre: nombre,
    nombre_normalizado: nombre.toLowerCase(),
    descripcion: 'Descripción de $nombre',
    tubo: tubo,
    anticoagulante: anticoagulante,
    volumen_ml: 3.0,
    area: area ?? 'General',
  );
}
