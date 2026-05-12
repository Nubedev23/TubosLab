import 'package:flutter/material.dart';

class AppStyles {
  //Colores
  static const Color primaryDark = Color(0xFF212121);
  static const Color primaryGray = Color(0xFFE0E0E0);
  static const Color accentColor = Color(0xFF42A5F5);
  static const Color cardColor = Colors.white;
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color secondaryColor = Color(0xFF1976D2);

  //Bordes y sombras
  static const double borderRadius = 15.0;

  static final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius),
  );
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    boxShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
  static const EdgeInsets padding = EdgeInsets.all(16.0);

  // ============================================
  // COLORES DE TUBOS
  // ============================================

  /// Mapa de colores exactos (para compatibilidad con código existente)
  static const Map<String, Color> coloresTubos = {
    'Lila': Color(0xFF9C27B0),
    'Celeste': Color(0xFF03A9F4),
    'Verde': Color(0xFF4CAF50),
    'Rojo': Color(0xFFE53935),
    'Gris': Color(0xFF757575),
    'Amarillo': Color(0xFFFDD835),
    'Azul': Color(0xFF1976D2),
    'Negro': Color(0xFF212121),
    'Blanco': Color(0xFFEEEEEE),
  };

  /// Obtiene el color a partir del texto del recipiente en cualquier formato.
  /// Funciona con "Tapa Roja", "tapa lila", "EDTA", "T. Roja", etc.
  static Color getColorForRecipiente(String recipiente) {
    final r = recipiente.toLowerCase();

    if (r.contains('rojo') || r.contains('roja')) return const Color(0xFFE53935);
    if (r.contains('lila') || r.contains('edta')) return const Color(0xFF9C27B0);
    if (r.contains('celeste') || r.contains('citrato')) return const Color(0xFF03A9F4);
    if (r.contains('verde') && r.contains('hormon')) return const Color(0xFF2E7D32);
    if (r.contains('verde')) return const Color(0xFF4CAF50);
    if (r.contains('gris') || r.contains('fluoruro')) return const Color(0xFF757575);
    if (r.contains('amarillo')) return const Color(0xFFFDD835);
    if (r.contains('azul')) return const Color(0xFF1976D2);
    if (r.contains('negro')) return const Color(0xFF212121);
    if (r.contains('blanco')) return const Color(0xFFEEEEEE);
    if (r.contains('frasco')) return const Color(0xFF0288D1);

    return const Color(0xFF9E9E9E); // gris por defecto
  }

  /// Versión legacy — usa getColorForRecipiente internamente
  /// para que el código existente que llama getColorForTubo siga funcionando
  static Color getColorForTubo(String nombreTubo) {
    // Primero intenta match exacto del mapa original
    final exact = coloresTubos[nombreTubo.trim()];
    if (exact != null) return exact;
    // Si no, usa la lógica flexible
    return getColorForRecipiente(nombreTubo);
  }

  /// Obtiene un color de texto apropiado según el fondo del tubo
  static Color getTextColorForTubo(String nombreTubo) {
    final backgroundColor = getColorForTubo(nombreTubo);
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Igual que getTextColorForTubo pero acepta texto libre del recipiente
  static Color getTextColorForRecipiente(String recipiente) {
    final backgroundColor = getColorForRecipiente(recipiente);
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Obtiene una versión más clara del color del tubo (para fondos)
  static Color getLightColorForTubo(String nombreTubo) {
    return getColorForTubo(nombreTubo).withOpacity(0.15);
  }

  static IconData getIconForTubo(String nombreTubo) {
    return Icons.science_outlined;
  }
}