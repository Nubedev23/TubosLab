// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/examen.dart'; // Importa el modelo de datos Examen

class FirestoreService {
  // 1. Obtiene la instancia Singleton de FirebaseFirestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. Referencia a la Colección 'examenes' con el conversor
  // El conversor convierte automáticamente los Maps de Firestore a objetos Examen de Dart
  late final CollectionReference<Examen> _examenesRef;

  FirestoreService() {
    // Inicializa la referencia y define cómo mapear los datos
    _examenesRef = _db
        .collection('examenes')
        .withConverter<Examen>(
          // fromFirestore: Convertir el Map de Firestore a objeto Examen
          fromFirestore: (snapshots, _) =>
              Examen.fromMap(snapshots.id, snapshots.data()!),
          // toFirestore: Convertir el objeto Examen a un Map para guardar en Firestore
          toFirestore: (examen, _) => examen.toMap(),
        );
  }

  // =========================================================================
  // OPERACIONES READ (Lectura y Búsqueda)
  // =========================================================================

  /// Obtiene un Stream de todos los exámenes (útil para listas que se actualizan solas).
  Stream<List<Examen>> getExamenesStream() {
    return _examenesRef.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  /// Obtiene un examen específico por su ID (usado en la edición del formulario).
  Future<Examen> getExamenById(String id) async {
    // Usa la referencia con el conversor, por lo que doc.data() devuelve un objeto Examen.
    final doc = await _examenesRef.doc(id).get();

    if (doc.exists && doc.data() != null) {
      return doc.data()!;
    }
    // Lanza una excepción si el documento no existe (ideal para manejo de errores en el formulario)
    throw Exception("Examen con ID $id no encontrado en la base de datos.");
  }

  // =========================================================================
  // BÚSQUEDA (Para la PantallaBusqueda)
  // =========================================================================

  /// Busca exámenes por nombre. Devuelve una lista de objetos Examen.
  Future<List<Examen>> searchExamenes(String query) async {
    if (query.isEmpty) return [];

    final String normalizedQuery = query.toLowerCase();

    // Nota: Esta consulta simple busca por el campo 'nombre' que EMPIECE con la query.
    // Firestore no soporta búsquedas que contengan la palabra en medio sin un índice externo.
    final QuerySnapshot<Examen> result = await _examenesRef
        .where('nombre', isGreaterThanOrEqualTo: query)
        .where(
          'nombre',
          isLessThan: query + '\uf8ff',
        ) // Truco para búsquedas que 'empiezan con'
        .get();

    // El conversor ya se encarga de que doc.data() sea un objeto Examen
    return result.docs.map((doc) => doc.data()).toList();
  }

  // =========================================================================
  // OPERACIONES WRITE (Crear y Actualizar)
  // =========================================================================

  /// Guarda un nuevo examen o actualiza uno existente (función del formulario).
  Future<void> saveExamen(Examen examen) async {
    if (examen.id.isEmpty) {
      // Si el ID está vacío, es un examen nuevo: agregamos y Firestore asigna un ID.
      await _examenesRef.add(examen);
    } else {
      // Si el ID existe, actualizamos el documento existente.
      // Usamos 'set' con el objeto Examen, el conversor lo mapea a Map.
      await _examenesRef.doc(examen.id).set(examen);
    }
  }

  /// Borra un examen por su ID.
  Future<void> deleteExamen(String id) async {
    await _examenesRef.doc(id).delete();
  }
}
