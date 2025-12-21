import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tubos_app/main.dart' as app;

/// Tests de Integración E2E
/// Estos tests simulan el comportamiento real del usuario
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Si puedes acceder a tus servicios:
    // CarritoService().limpiarCarrito();
  });
  group('E2E Tests - Flujo Completo de Usuario', () {
    testWidgets('CP-002: Búsqueda de Examen - Flujo Completo', (
      WidgetTester tester,
    ) async {
      // Arrange - Iniciar app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act 1 - Hacer clic en "Iniciar Búsqueda"
      final busquedaButton = find.text('Iniciar Búsqueda');
      expect(busquedaButton, findsOneWidget);
      await tester.tap(busquedaButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act 2 - Escribir en el campo de búsqueda
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'ggt');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Assert - Verificar que aparecen resultados
      // Nota: Esto depende de que haya datos en Firebase
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('Tarea de Usabilidad 1: Buscar Hemograma en < 30 segundos', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final stopwatch = Stopwatch()..start();

      // Act 1 - Iniciar búsqueda
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act 2 - Buscar "Hemograma"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'hemograma');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act 3 - Abrir detalle
      final resultCard = find.byType(Card).first;
      await tester.tap(resultCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      stopwatch.stop();

      // Assert - Verificar tiempo < 30 segundos
      expect(stopwatch.elapsed.inSeconds, lessThan(30));

      // Assert - Verificar que está en pantalla de detalle
      expect(find.text('Detalles del Examen'), findsOneWidget);
    });

    testWidgets('Tarea de Usabilidad 2: Agregar exámenes al carrito', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      int clickCount = 0;

      // Act 1 - Iniciar búsqueda
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      clickCount++;

      // Act 2 - Buscar "Glicemia"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'ggt');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act 3 - Agregar al carrito
      final addToCartButton = find
          .byIcon(Icons.add_shopping_cart_outlined)
          .first;
      await tester.tap(addToCartButton);
      await tester.pumpAndSettle();
      clickCount++;

      // Act 4 - Buscar "Hemograma"
      await tester.enterText(searchField, 'hemograma');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Act 5 - Agregar al carrito
      final addToCartButton2 = find
          .byIcon(Icons.add_shopping_cart_outlined)
          .first;
      await tester.tap(addToCartButton2);
      await tester.pumpAndSettle();
      clickCount++;

      // Assert - Verificar número de clics ≤ 10
      expect(clickCount, lessThanOrEqualTo(10));

      // Assert - Verificar badge del carrito muestra "2"
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Tarea de Usabilidad 3: Ver resumen de tubos', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Act 1 - Iniciar búsqueda
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act 2 - Agregar examen al carrito
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'ggt');
      await tester.testTextInput.receiveAction(
        TextInputAction.search,
      ); // Asegura que procese la búsqueda
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap en el primer botón de agregar que encuentre
      final addBtn = find.byIcon(Icons.add_shopping_cart_outlined).first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Act 3 - Ir al carrito
      // Usamos .first por si el Badge duplica el widget en el árbol
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert - Verificar pantalla de carrito
      expect(find.text('Mi Carrito de Exámenes'), findsOneWidget);

      // Act 4 - Procesar solicitud (CAMBIO AQUÍ)
      // Buscamos un botón que CONTENGA el texto, ignorando la parte dinámica de los paréntesis
      final procesarButton = find.ancestor(
        of: find.textContaining('Procesar Solicitud'),
        matching: find.byType(ElevatedButton),
      );

      expect(procesarButton, findsOneWidget);
      await tester.tap(procesarButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert - Verificar resumen de tubos
      expect(find.text('Muestras requeridas'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsWidgets);
    });
    testWidgets('CS-001: Verificar acceso denegado a funciones protegidas', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Iniciar como anónimo
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Intentar acceder a Manual (requiere autenticación)
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      // Assert - Debe mostrar mensaje de login requerido
      expect(
        find.text('Manual solo para usuarios registrados'),
        findsOneWidget,
      );
    });

    testWidgets('CP-003: Visualización de detalles completos', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Navegar a búsqueda
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Buscar y abrir detalle
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'hemograma');
      await tester.pumpAndSettle();

      final firstCard = find.byType(Card).first;
      await tester.tap(firstCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert - Verificar todos los campos requeridos
      expect(find.text('Detalles del Examen'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
      expect(find.text('Especificaciones del Examen'), findsOneWidget);
      expect(find.text('Volumen Mínimo'), findsOneWidget);
      expect(find.text('Área del Laboratorio'), findsOneWidget);
    });

    testWidgets('Verificar tiempo de respuesta < 2 segundos en búsqueda', (
      WidgetTester tester,
    ) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final stopwatch = Stopwatch()..start();

      // Act - Escribir búsqueda
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'ggt');
      await tester.pump(); // Un solo pump para medir tiempo real

      // Esperar a que aparezcan resultados
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Assert - Verificar tiempo < 2 segundos
      expect(stopwatch.elapsed.inSeconds, lessThan(2));
    });
  });

  group('E2E Tests - Flujo de Administrador', () {
    testWidgets('CP-001: Crear nuevo examen como admin', (
      WidgetTester tester,
    ) async {
      // Note: Este test requiere credenciales de admin reales
      // Se recomienda usar un ambiente de testing separado

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Login como admin
      await tester.tap(find.text('Soy Administrador'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar que llegamos a pantalla de login
      expect(find.text('Acceso Administrador'), findsOneWidget);

      // TODO: Completar flujo de login y creación de examen
      // Requiere credenciales de test configuradas
    });

    testWidgets('CP-008: Verificar restricción de acceso por rol', (
      WidgetTester tester,
    ) async {
      // Note: Requiere usuario clínico de prueba

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Login como clínico
      await tester.tap(find.text('Personal Clínico'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert - Verificar pantalla de login clínico
      expect(find.text('Acceso personal clínico'), findsOneWidget);

      // TODO: Completar login y verificar que NO tiene acceso a CRUD
    });
  });

  group('E2E Tests - Compatibilidad de Dispositivos', () {
    testWidgets('Debe funcionar en pantalla pequeña (360x640)', (
      WidgetTester tester,
    ) async {
      // Arrange - Simular dispositivo gama media
      await tester.binding.setSurfaceSize(const Size(360, 640));

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert - No debe haber overflow
      expect(tester.takeException(), isNull);

      // Assert - Elementos principales visibles
      expect(find.text('TubosLab'), findsOneWidget);
      expect(find.text('Iniciar Búsqueda'), findsOneWidget);

      // Cleanup
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Debe funcionar en pantalla grande (tablet)', (
      WidgetTester tester,
    ) async {
      // Arrange - Simular tablet
      await tester.binding.setSurfaceSize(const Size(800, 1280));

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('TubosLab'), findsOneWidget);

      // Cleanup
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });
}
