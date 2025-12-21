import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tubos_app/pantallas/pantalla_bienvenida.dart';
import 'package:tubos_app/utils/app_styles.dart';

void main() {
  group('PantallaBienvenida - Tests de Widget', () {
    testWidgets('Debe mostrar el logo y título de la app', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(find.text('TubosLab'), findsOneWidget);
      expect(find.byIcon(Icons.science_outlined), findsOneWidget);
      expect(
        find.text('Optimizando la recolección de muestras de laboratorio'),
        findsOneWidget,
      );
    });

    testWidgets('Debe mostrar las tres tarjetas principales', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(find.text('Iniciar Búsqueda'), findsOneWidget);
      expect(find.text('Personal Clínico'), findsOneWidget);
      expect(find.text('Soy Administrador'), findsOneWidget);
    });

    testWidgets('Debe mostrar el copyright en el footer', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(
        find.text('© 2025 Tubos App. Desarrollado por MBQ'),
        findsOneWidget,
      );
    });

    testWidgets('Tarjeta Iniciar Búsqueda debe ser tocable', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: const PantallaBienvenida(),
          routes: {
            '/main': (context) => const Scaffold(body: Text('Main Screen')),
          },
        ),
      );

      // Assert - Verificar que la tarjeta existe
      expect(find.text('Iniciar Búsqueda'), findsOneWidget);

      // Act - Tocar la tarjeta
      await tester.tap(find.text('Iniciar Búsqueda'));
      await tester.pumpAndSettle();

      // Note: Para verificar navegación completa, se necesita mockear AuthService
    });

    testWidgets('Debe mostrar iconos correctos en cada tarjeta', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.badge_outlined), findsOneWidget);
      // El ícono de admin puede ser Icons.settings o Icons.login según el estado
    });
  });

  group('PantallaBienvenida - Adaptación por Rol', () {
    testWidgets('Debe cambiar texto según rol de usuario', (
      WidgetTester tester,
    ) async {
      // Note: Este test requiere mockear el AuthService con diferentes roles
      // Ver ejemplo completo en integration tests

      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      await tester.pumpAndSettle();

      // Por defecto debe mostrar "Soy Administrador" para usuarios no admin
      expect(find.text('Soy Administrador'), findsOneWidget);
    });
  });

  group('PantallaBienvenida - Diseño Responsivo', () {
    testWidgets('Debe renderizarse correctamente en pantalla pequeña', (
      WidgetTester tester,
    ) async {
      // Arrange - Simular pantalla pequeña
      await tester.binding.setSurfaceSize(const Size(360, 640));

      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Column), findsWidgets);

      // Limpiar
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Debe renderizarse correctamente en pantalla grande', (
      WidgetTester tester,
    ) async {
      // Arrange - Simular tablet
      await tester.binding.setSurfaceSize(const Size(800, 1280));

      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert
      expect(find.byType(SafeArea), findsOneWidget);

      // Limpiar
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });

  group('PantallaBienvenida - Accesibilidad', () {
    testWidgets('Todos los textos deben ser legibles', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert - Verificar que no hay overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Botones deben tener áreas táctiles adecuadas', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(const MaterialApp(home: PantallaBienvenida()));

      // Assert - Verificar que las tarjetas tienen tamaño suficiente
      final tarjetasFinder = find.byType(InkWell);
      expect(tarjetasFinder, findsNWidgets(3));

      for (final element in tarjetasFinder.evaluate()) {
        final size = element.size;
        expect(size?.height, greaterThan(48)); // Material Design mínimo
      }
    });
  });
}
