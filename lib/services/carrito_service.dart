import 'package:flutter/foundation.dart';
import '../models/examen.dart';

/// Servicio de Carrito de Exámenes usando el patrón Singleton.
/// Utiliza ValueNotifier para la gestión de estado reactiva,
/// permitiendo que los widgets escuchen los cambios en la lista de exámenes.
class CarritoService {
  // Patrón Singleton
  static final CarritoService _instance = CarritoService._internal();
  factory CarritoService() => _instance;
  CarritoService._internal();

  // ValueNotifier es una forma simple de gestionar el estado.
  // Notifica a sus listeners cuando el valor (la lista de exámenes) cambia.
  final ValueNotifier<List<Examen>> _examenesEnCarrito =
      ValueNotifier<List<Examen>>([]);

  /// Getter para exponer la lista de exámenes de forma reactiva.
  ValueListenable<List<Examen>> get examenesEnCarritoListenable =>
      _examenesEnCarrito;

  /// Añade un examen al carrito si no está ya presente.
  void agregarExamen(Examen examen) {
    // Usamos la lista actual como una nueva variable para evitar mutar el valor directamente
    final currentList = _examenesEnCarrito.value;

    // Solo agregar si el examen no existe (comparando por ID)
    if (!currentList.any((e) => e.id == examen.id)) {
      final updatedList = List<Examen>.from(currentList)..add(examen);
      _examenesEnCarrito.value = updatedList;
      debugPrint('Examen agregado al carrito: ${examen.nombre}');
    } else {
      debugPrint('El examen ${examen.nombre} ya está en el carrito.');
    }
  }

  /// Elimina un examen del carrito.
  void removerExamen(String examenId) {
    final updatedList = _examenesEnCarrito.value
        .where((examen) => examen.id != examenId)
        .toList();
    _examenesEnCarrito.value = updatedList;
    debugPrint('Examen removido del carrito con ID: $examenId');
  }

  /// Limpia todos los exámenes del carrito.
  void limpiarCarrito() {
    _examenesEnCarrito.value = [];
    debugPrint('Carrito limpiado.');
  }

  /// Devuelve true si el examen ya está en el carrito.
  bool estaEnCarrito(String examenId) {
    return _examenesEnCarrito.value.any((e) => e.id == examenId);
  }
}
