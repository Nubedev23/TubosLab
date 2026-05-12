import 'package:flutter/foundation.dart';
import '../models/examen.dart';

class ResumenRecipiente {
  final String titulo;
  final String subtitulo;
  final String recipiente;
  final int cantidad;
  final List<String> examenes;
  final bool esDeriivado;
  final String? seccion;

  ResumenRecipiente({
    required this.titulo,
    required this.subtitulo,
    required this.recipiente,
    required this.cantidad,
    required this.examenes,
    required this.esDeriivado,
    this.seccion,
  });
}

class CarritoService {
  static final CarritoService _instance = CarritoService._internal();
  factory CarritoService() => _instance;
  CarritoService._internal();

  final ValueNotifier<List<Examen>> _examenesEnCarrito =
      ValueNotifier<List<Examen>>([]);

  ValueListenable<List<Examen>> get examenesEnCarritoListenable =>
      _examenesEnCarrito;

  void agregarExamen(Examen examen) {
    final current = _examenesEnCarrito.value;
    if (!current.any((e) => e.id == examen.id)) {
      _examenesEnCarrito.value = List<Examen>.from(current)..add(examen);
    }
  }

  void removerExamen(String examenId) {
    _examenesEnCarrito.value =
        _examenesEnCarrito.value.where((e) => e.id != examenId).toList();
  }

  void limpiarCarrito() => _examenesEnCarrito.value = [];

  bool estaEnCarrito(String examenId) =>
      _examenesEnCarrito.value.any((e) => e.id == examenId);

  /// Agrupa internos por recipiente, derivados por sección+recipiente.
  /// Internos primero, derivados al final.
  List<ResumenRecipiente> obtenerResumenPorRecipiente() {
    final examenes = _examenesEnCarrito.value;
    final Map<String, List<Examen>> grupos = {};

    for (final e in examenes) {
      final key = e.es_derivado
          ? 'D::${e.seccion}::${e.recipiente.trim()}'
          : 'I::${e.recipiente.trim()}';
      grupos.putIfAbsent(key, () => []);
      grupos[key]!.add(e);
    }

    final resumen = grupos.entries.map((entry) {
      final partes = entry.key.split('::');
      final esDer = partes[0] == 'D';
      final seccion = esDer ? partes[1] : null;
      final first = entry.value.first;

      return ResumenRecipiente(
        titulo: esDer ? seccion! : first.recipienteCorto,
        subtitulo: first.recipiente.trim(),
        recipiente: first.recipiente.trim(),
        cantidad: 1,
        examenes: entry.value.map((e) => e.nombre).toList(),
        esDeriivado: esDer,
        seccion: seccion,
      );
    }).toList();

    resumen.sort((a, b) {
      if (a.esDeriivado != b.esDeriivado) return a.esDeriivado ? 1 : -1;
      return a.titulo.compareTo(b.titulo);
    });

    return resumen;
  }

  // Alias retrocompatible
  List<ResumenRecipiente> obtenerResumenPorTubo() =>
      obtenerResumenPorRecipiente();
}
