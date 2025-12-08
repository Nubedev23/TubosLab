import 'package:flutter/foundation.dart';
import '../models/examen.dart';

/// Define la estructura del resumen agrupado por tubo
class ResumenTubo {
  final String tubo;
  final String anticoagulante;
  final int cantidad;
  final List<String> examenes; // Lista de exámenes que requieren este tubo

  ResumenTubo({
    required this.tubo,
    required this.anticoagulante,
    required this.cantidad,
    required this.examenes,
  });
}

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

  // =========================================================================
  // LÓGICA DE AGRUPACIÓN POR TUBO
  // =========================================================================

  /// Genera un resumen de los tubos necesarios basado en los exámenes en el carrito.
  /// Agrupa por la combinación única de 'tubo' y 'anticoagulante' y, opcionalmente, 'area'.
  List<ResumenTubo> obtenerResumenPorTubo() {
    final examenes = _examenesEnCarrito.value;

    // Un mapa para agrupar los exámenes por una clave única (Area + Tubo + Anticoagulante)
    final Map<String, List<Examen>> grupos = {};

    for (var examen in examenes) {
      // Creamos una clave única para el agrupamiento.
      // Se recomienda incluir 'area' para diferenciar, aunque el tubo sea el mismo.
      // Si el campo 'area' no está en tu modelo, usa solo tubo::anticoagulante
      // Asumimos que 'area', 'tubo' y 'anticoagulante' son Strings no nulos en el modelo Examen.
      final key = '${examen.area}::${examen.tubo}::${examen.anticoagulante}';

      // Inicializamos la lista si la clave es nueva
      grupos.putIfAbsent(key, () => []);

      // Agregamos el examen al grupo
      grupos[key]!.add(examen);
    }

    // Convertimos el mapa de grupos a una lista de ResumenTubo
    final List<ResumenTubo> resumen = [];
    grupos.forEach((key, listaDeExamenes) {
      // Extraemos los datos de la clave para la presentación.
      final parts = key.split('::');
      final area = parts.length > 2 ? parts[0] : ''; // Si hay área, la tomamos
      final tubo = parts.length > 1 ? parts[parts.length - 2] : 'Desconocido';
      final anticoagulante = parts.length > 1
          ? parts[parts.length - 1]
          : 'Ninguno';

      // Creamos la lista de nombres de exámenes para el detalle
      final nombresExamenes = listaDeExamenes.map((e) => e.nombre).toList();

      resumen.add(
        ResumenTubo(
          // Combinamos Área y Tubo para una mejor visualización en el resumen
          tubo: area.isNotEmpty ? '$area - $tubo' : tubo,
          anticoagulante: anticoagulante,
          cantidad: 1, // La cantidad es 1 por cada tipo de tubo único requerido
          examenes: nombresExamenes,
        ),
      );
    });

    // Opcional: Ordenar el resumen por área/tubo para que sea más fácil de leer
    resumen.sort((a, b) => a.tubo.compareTo(b.tubo));

    return resumen;
  }
}
