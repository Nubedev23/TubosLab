class QueryHistory {
  final String examenId;
  final String examenNombre;
  final String tubo;
  final String anticoagulante;
  final DateTime timestamp;
  final String? userId; // ID del usuario que realizó la consulta

  QueryHistory({
    required this.examenId,
    required this.examenNombre,
    required this.tubo,
    required this.anticoagulante,
    required this.timestamp,
    this.userId,
  });

  // Convertir a JSON para guardar en SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'examenId': examenId,
      'examenNombre': examenNombre,
      'tubo': tubo,
      'anticoagulante': anticoagulante,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  // Crear desde JSON
  factory QueryHistory.fromJson(Map<String, dynamic> json) {
    return QueryHistory(
      examenId: json['examenId'] as String,
      examenNombre: json['examenNombre'] as String,
      tubo: json['tubo'] as String,
      anticoagulante: json['anticoagulante'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
    );
  }
}
