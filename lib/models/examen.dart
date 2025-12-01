import 'package:cloud_firestore/cloud_firestore.dart';

class Examen {
  final String? id;
  final String nombre;
  final String nombre_normalizado;
  final String descripcion;
  final String tubo;
  final String anticoagulante;
  final double volumen_ml;

  final String? area;

  final DateTime? ultimaActualizacion;
  final String? updatedBy;

  Examen({
    this.id,
    required this.nombre,
    required this.nombre_normalizado,
    required this.descripcion,
    required this.tubo,
    required this.anticoagulante,
    required this.volumen_ml,
    required this.area,
    this.ultimaActualizacion,
    this.updatedBy,
  });

  factory Examen.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['ultima_acualizacion'] as Timestamp?;

    return Examen(
      id: id,
      nombre: map['nombre'] ?? 'Sin Nombre',
      nombre_normalizado: map['nombre_normalizado'] ?? '',
      descripcion: map['descripcion'] ?? 'Sin descripción',
      tubo: map['tubo'] ?? 'No especificado',
      anticoagulante: map['anticoagulante'] ?? 'N/A',
      volumen_ml: (map['volumen_ml'] as num?)?.toDouble() ?? 0.0,
      area: map['area'] as String?,

      ultimaActualizacion: timestamp?.toDate(),
      updatedBy: map['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      //'nombre_normalizado': nombre.toLowerCase(),
      'descripcion': descripcion,
      'tubo': tubo,
      'anticoagulante': anticoagulante,
      'volumen_ml': volumen_ml,
      'area': area,
    };
  }

  Examen copyWith({
    String? id,
    String? nombre,
    String? nombre_normalizado,
    String? descripcion,
    String? tubo,
    String? anticoagulante,
    double? volumen_ml,
    String? area,
    DateTime? ultimaActualizacion,
    String? updatedBy,
  }) {
    return Examen(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nombre_normalizado: nombre_normalizado ?? this.nombre_normalizado,
      descripcion: descripcion ?? this.descripcion,
      tubo: tubo ?? this.tubo,
      anticoagulante: anticoagulante ?? this.anticoagulante,
      volumen_ml: volumen_ml ?? this.volumen_ml,
      area: area ?? this.area,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  String get tuboComboId => '${tubo}_$anticoagulante';
}
