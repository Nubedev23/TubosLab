class Examen {
  final String id;
  final String nombre;
  final String nombre_normalizado;
  final String descripcion;
  final String tubo;
  final String anticoagulante;
  final double volumen_ml;

  final String? area;

  Examen({
    required this.id,
    required this.nombre,
    required this.nombre_normalizado,
    required this.descripcion,
    required this.tubo,
    required this.anticoagulante,
    required this.volumen_ml,
    required this.area,
  });

  factory Examen.fromMap(String id, Map<String, dynamic> map) {
    return Examen(
      id: id,
      nombre: map['nombre'] ?? 'Sin Nombre',
      nombre_normalizado: map['nombre_normalizado'] ?? '',
      descripcion: map['descripcion'] ?? 'Sin descripción',
      tubo: map['tubo'] ?? 'No especificado',
      anticoagulante: map['anticoagulante'] ?? 'N/A',
      volumen_ml: (map['volumen_ml'] as num?)?.toDouble() ?? 0.0,
      area: map['area'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'nombre_normalizado': nombre.toLowerCase(),
      'descripcion': descripcion,
      'tubo': tubo,
      'anticoagulante': anticoagulante,
      'volumen_ml': volumen_ml,
      'area': area,

      'ultima_actualizacion': DateTime.now().toIso8601String(),
    };
  }
}
