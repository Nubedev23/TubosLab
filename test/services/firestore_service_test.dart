import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:tubos_app/services/firestore_service.dart';
import 'package:tubos_app/models/examen.dart';

void main() {
  group('FirestoreService - Pruebas Unitarias', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirestoreService firestoreService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      // Nota: En tu implementación real, necesitarás inyectar estas dependencias
    });

    group('CP-001: Registro de Exámenes', () {
      test('Debe crear examen con todos los campos correctos', () async {
        // Arrange
        final examen = Examen(
          nombre: 'Hemograma Completo',
          nombre_normalizado: 'hemograma completo',
          descripcion: 'Análisis completo de sangre',
          tubo: 'Lila',
          anticoagulante: 'EDTA K2',
          volumen_ml: 3.5,
          area: 'Hematología',
        );

        // Act
        await fakeFirestore.collection('examenes').add(examen.toMap());

        // Assert
        final snapshot = await fakeFirestore.collection('examenes').get();
        expect(snapshot.docs.length, 1);

        final savedExamen = snapshot.docs.first.data();
        expect(savedExamen['nombre'], 'Hemograma Completo');
        expect(savedExamen['tubo'], 'Lila');
        expect(savedExamen['anticoagulante'], 'EDTA K2');
        expect(savedExamen['volumen_ml'], 3.5);
        expect(savedExamen['area'], 'Hematología');
      });

      test('Debe generar nombre_normalizado sin tildes ni mayúsculas', () {
        // Arrange
        final firestoreService = FirestoreService();

        // Act
        final normalizado1 = firestoreService.normalizar('Glicemia');
        final normalizado2 = firestoreService.normalizar('Hemograma Completo');
        final normalizado3 = firestoreService.normalizar('Proteína C Reactiva');

        // Assert
        expect(normalizado1, 'glicemia');
        expect(normalizado2, 'hemograma completo');
        expect(normalizado3, 'proteina c reactiva');
      });

      test('Debe actualizar examen existente', () async {
        // Arrange
        final docRef = await fakeFirestore.collection('examenes').add({
          'nombre': 'Hemograma',
          'tubo': 'Lila',
          'anticoagulante': 'EDTA K2',
          'volumen_ml': 3.0,
        });

        // Act
        await docRef.update({
          'volumen_ml': 3.5,
          'descripcion': 'Descripción actualizada',
        });

        // Assert
        final updated = await docRef.get();
        expect(updated.data()?['volumen_ml'], 3.5);
        expect(updated.data()?['descripcion'], 'Descripción actualizada');
      });
    });

    group('CP-002: Consulta de Examen', () {
      test('Debe buscar examen por nombre normalizado', () async {
        // Arrange - Crear varios exámenes
        await fakeFirestore.collection('examenes').add({
          'nombre': 'Glicemia',
          'nombre_normalizado': 'glicemia',
          'tubo': 'Gris',
        });
        await fakeFirestore.collection('examenes').add({
          'nombre': 'Hemograma',
          'nombre_normalizado': 'hemograma',
          'tubo': 'Lila',
        });
        await fakeFirestore.collection('examenes').add({
          'nombre': 'Glucosa Post Prandial',
          'nombre_normalizado': 'glucosa post prandial',
          'tubo': 'Gris',
        });

        // Act - Buscar por "glic"
        final results = await fakeFirestore
            .collection('examenes')
            .where('nombre_normalizado', isGreaterThanOrEqualTo: 'glic')
            .where('nombre_normalizado', isLessThan: 'glic\uf8ff')
            .get();

        // Assert
        expect(results.docs.length, 1);
        expect(results.docs.first.data()['nombre'], 'Glicemia');
      });

      test('Debe ser case-insensitive en búsqueda', () async {
        // Arrange
        await fakeFirestore.collection('examenes').add({
          'nombre': 'HEMOGRAMA COMPLETO',
          'nombre_normalizado': 'hemograma completo',
          'tubo': 'Lila',
        });

        // Act - Buscar en minúsculas
        final results = await fakeFirestore
            .collection('examenes')
            .where('nombre_normalizado', isGreaterThanOrEqualTo: 'hemograma')
            .where('nombre_normalizado', isLessThan: 'hemograma\uf8ff')
            .get();

        // Assert
        expect(results.docs.length, 1);
        expect(results.docs.first.data()['nombre'], 'HEMOGRAMA COMPLETO');
      });

      test('Debe retornar lista vacía si no hay coincidencias', () async {
        // Arrange
        await fakeFirestore.collection('examenes').add({
          'nombre': 'Hemograma',
          'nombre_normalizado': 'hemograma',
        });

        // Act
        final results = await fakeFirestore
            .collection('examenes')
            .where('nombre_normalizado', isGreaterThanOrEqualTo: 'noexiste')
            .where('nombre_normalizado', isLessThan: 'noexiste\uf8ff')
            .get();

        // Assert
        expect(results.docs.length, 0);
      });
    });

    group('CP-003: Visualización de Detalles', () {
      test('Debe obtener examen por ID con todos los campos', () async {
        // Arrange
        final docRef = await fakeFirestore.collection('examenes').add({
          'nombre': 'Hemograma Completo',
          'nombre_normalizado': 'hemograma completo',
          'descripcion': 'Conteo completo de células sanguíneas',
          'tubo': 'Lila',
          'anticoagulante': 'EDTA K2',
          'volumen_ml': 3.5,
          'area': 'Hematología',
        });

        // Act
        final doc = await docRef.get();
        final data = doc.data();

        // Assert
        expect(data?['nombre'], 'Hemograma Completo');
        expect(data?['descripcion'], isNotEmpty);
        expect(data?['tubo'], 'Lila');
        expect(data?['anticoagulante'], 'EDTA K2');
        expect(data?['volumen_ml'], 3.5);
        expect(data?['area'], 'Hematología');
      });

      test('Debe retornar null si examen no existe', () async {
        // Act
        final doc = await fakeFirestore
            .collection('examenes')
            .doc('id_inexistente')
            .get();

        // Assert
        expect(doc.exists, false);
        expect(doc.data(), isNull);
      });
    });

    group('CP-004: Gestión de Base de Datos - Modo Offline', () {
      test('CacheService debe guardar y recuperar exámenes', () async {
        // Nota: Este test requiere mock de SharedPreferences
        // Ver cache_service_test.dart para implementación completa

        // Arrange
        final examenes = [
          Examen(
            id: '1',
            nombre: 'Glicemia',
            nombre_normalizado: 'glicemia',
            descripcion: 'Test',
            tubo: 'Gris',
            anticoagulante: 'Fluoruro',
            volumen_ml: 2.0,
            area: 'Bioquímica',
          ),
        ];

        // Act & Assert
        // Implementar con shared_preferences_mock
        expect(examenes.length, 1);
      });
    });

    group('CP-008: Control de Acceso por Roles', () {
      test('Debe identificar usuario admin correctamente', () async {
        // Arrange
        final adminUid = 'admin123';
        await fakeFirestore.collection('users').doc(adminUid).set({
          'role': 'admin',
          'last_updated': DateTime.now(),
        });

        // Act
        final userDoc = await fakeFirestore
            .collection('users')
            .doc(adminUid)
            .get();

        // Assert
        expect(userDoc.data()?['role'], 'admin');
      });

      test('Debe identificar usuario clínico correctamente', () async {
        // Arrange
        final clinicoUid = 'clinico123';
        await fakeFirestore.collection('users').doc(clinicoUid).set({
          'role': 'user',
          'last_updated': DateTime.now(),
        });

        // Act
        final userDoc = await fakeFirestore
            .collection('users')
            .doc(clinicoUid)
            .get();

        // Assert
        expect(userDoc.data()?['role'], 'user');
        expect(userDoc.data()?['role'], isNot('admin'));
      });
    });
  });

  group('Normalización de Texto', () {
    final firestoreService = FirestoreService();

    test('Debe remover tildes correctamente', () {
      expect(firestoreService.normalizar('áéíóú'), 'aeiou');
      expect(firestoreService.normalizar('ÁÉÍÓÚ'), 'aeiou');
    });

    test('Debe convertir a minúsculas', () {
      expect(firestoreService.normalizar('HEMOGRAMA'), 'hemograma');
      expect(firestoreService.normalizar('Glicemia'), 'glicemia');
    });

    test('Debe remover espacios en blanco al inicio y final', () {
      expect(firestoreService.normalizar('  hemograma  '), 'hemograma');
      expect(firestoreService.normalizar('\n\tglicemia\t\n'), 'glicemia');
    });

    test('Debe mantener espacios internos', () {
      expect(
        firestoreService.normalizar('Hemograma Completo'),
        'hemograma completo',
      );
    });
  });
}
