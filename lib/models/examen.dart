import 'package:cloud_firestore/cloud_firestore.dart';

class Examen {
  final String? id;
  final String nombre;
  final String nombre_normalizado;

  // Datos de la muestra
  final String condicion_paciente;
  final String muestra;
  final String recipiente;
  final String conservacion_transporte;
  final String seccion;
  final String plazo_entrega;
  final String observaciones;

  // Clasificación
  final String? area;
  final bool es_derivado;

  // Disponibilidad horaria
  final bool disponible_urgencia;
  final String horario_disponibilidad;

  final DateTime? ultimaActualizacion;
  final String? updatedBy;

  Examen({
    this.id,
    required this.nombre,
    required this.nombre_normalizado,
    required this.condicion_paciente,
    required this.muestra,
    required this.recipiente,
    required this.conservacion_transporte,
    required this.seccion,
    required this.plazo_entrega,
    required this.observaciones,
    this.area,
    this.es_derivado = false,
    this.disponible_urgencia = false,
    this.horario_disponibilidad = 'Lunes a jueves 8:00–17:00, viernes 8:00–16:00',
    this.ultimaActualizacion,
    this.updatedBy,
  });

  factory Examen.fromMap(Map<String, dynamic> map, String id) {
    final timestamp = map['ultima_actualizacion'] as Timestamp?;
    return Examen(
      id: id,
      nombre: map['nombre'] ?? 'Sin Nombre',
      nombre_normalizado: map['nombre_normalizado'] ?? '',
      condicion_paciente: map['condicion_paciente'] ?? 'No requiere',
      muestra: map['muestra'] ?? 'No especificada',
      recipiente: map['recipiente'] ?? 'No especificado',
      conservacion_transporte: map['conservacion_transporte'] ?? 'Tº ambiente',
      seccion: map['seccion'] ?? 'Sin sección',
      plazo_entrega: map['plazo_entrega'] ?? 'Consultar',
      observaciones: map['observaciones'] ?? '',
      area: map['area'] as String?,
      es_derivado: map['es_derivado'] as bool? ?? false,
      disponible_urgencia: map['disponible_urgencia'] as bool? ?? false,
      horario_disponibilidad: map['horario_disponibilidad'] as String? ??
          'Lunes a jueves 8:00–17:00, viernes 8:00–16:00',
      ultimaActualizacion: timestamp?.toDate(),
      updatedBy: map['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'nombre_normalizado': nombre_normalizado,
      'condicion_paciente': condicion_paciente,
      'muestra': muestra,
      'recipiente': recipiente,
      'conservacion_transporte': conservacion_transporte,
      'seccion': seccion,
      'plazo_entrega': plazo_entrega,
      'observaciones': observaciones,
      'area': area,
      'es_derivado': es_derivado,
      'disponible_urgencia': disponible_urgencia,
      'horario_disponibilidad': horario_disponibilidad,
    };
  }

  Examen copyWith({
    String? id,
    String? nombre,
    String? nombre_normalizado,
    String? condicion_paciente,
    String? muestra,
    String? recipiente,
    String? conservacion_transporte,
    String? seccion,
    String? plazo_entrega,
    String? observaciones,
    String? area,
    bool? es_derivado,
    bool? disponible_urgencia,
    String? horario_disponibilidad,
    DateTime? ultimaActualizacion,
    String? updatedBy,
  }) {
    return Examen(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombre_normalizado: nombre_normalizado ?? this.nombre_normalizado,
      condicion_paciente: condicion_paciente ?? this.condicion_paciente,
      muestra: muestra ?? this.muestra,
      recipiente: recipiente ?? this.recipiente,
      conservacion_transporte: conservacion_transporte ?? this.conservacion_transporte,
      seccion: seccion ?? this.seccion,
      plazo_entrega: plazo_entrega ?? this.plazo_entrega,
      observaciones: observaciones ?? this.observaciones,
      area: area ?? this.area,
      es_derivado: es_derivado ?? this.es_derivado,
      disponible_urgencia: disponible_urgencia ?? this.disponible_urgencia,
      horario_disponibilidad: horario_disponibilidad ?? this.horario_disponibilidad,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  /// Devuelve true si el examen está disponible en este momento
  bool estaDisponibleAhora() {
    if (disponible_urgencia) return true;
    final now = DateTime.now();
    final weekday = now.weekday; // 1=lun … 7=dom
    final timeInMinutes = now.hour * 60 + now.minute;
    if (weekday == 6 || weekday == 7) return false;         // fin de semana
    if (weekday >= 1 && weekday <= 4) {                     // lun–jue 8–17
      return timeInMinutes >= 480 && timeInMinutes < 1020;
    }
    if (weekday == 5) {                                     // vie 8–16
      return timeInMinutes >= 480 && timeInMinutes < 960;
    }
    return false;
  }

  String get recipienteCorto {
    final r = recipiente.toLowerCase();
    if (r.contains('tapa roja')) return 'Tapa Roja';
    if (r.contains('tapa lila') || r.contains('edta')) return 'Tapa Lila';
    if (r.contains('tapa celeste') || r.contains('citrato')) return 'Tapa Celeste';
    if (r.contains('tapa verde') && r.contains('hormonas')) return 'Verde Hormonas';
    if (r.contains('tapa verde') && r.contains('química')) return 'Verde Química';
    if (r.contains('tapa verde')) return 'Tapa Verde';
    if (r.contains('tapa gris') || r.contains('fluoruro')) return 'Tapa Gris';
    if (r.contains('frasco') && r.contains('estéril')) return 'Frasco Estéril';
    if (r.contains('frasco')) return 'Frasco Limpio';
    if (r.contains('papel filtro')) return 'Papel Filtro';
    if (r.contains('portaobjeto') || r.contains('cinta')) return 'Portaobjetos';
    if (r.contains('hisopo') || r.contains('tórula') || r.contains('torula')) {
      return 'Hisopo/Tórula';
    }
    return recipiente.length > 28 ? '${recipiente.substring(0, 26)}…' : recipiente;
  }

  String get carritoGroupKey => es_derivado
      ? 'derivado::$seccion::$recipiente'
      : 'interno::$recipiente';
}
