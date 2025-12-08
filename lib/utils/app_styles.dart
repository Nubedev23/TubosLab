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

  /// Mapa de colores según el tipo de tubo de laboratorio
  static const Map<String, Color> coloresTubos = {
    'Lila': Color(0xFF9C27B0), // Lila (EDTA)
    'Celeste': Color(0xFF03A9F4), // Celeste (Citrato)
    'Verde': Color(0xFF4CAF50), // Verde (Heparina)
    'Rojo': Color(0xFFE53935), // Rojo (Sin aditivo)
    'Gris': Color(0xFF757575), // Gris (Fluoruro)
    'Amarillo': Color(0xFFFDD835), // Amarillo
    'Azul': Color(0xFF1976D2), // Azul oscuro
    'Negro': Color(0xFF212121), // Negro
    'Blanco': Color(0xFFEEEEEE), // Blanco
  };

  /// Obtiene el color correspondiente al tubo
  /// Si no encuentra el tubo, devuelve un color por defecto (gris)
  static Color getColorForTubo(String nombreTubo) {
    final tuboNormalizado = nombreTubo.trim();
    return coloresTubos[tuboNormalizado] ?? const Color(0xFF9E9E9E);
  }

  /// Obtiene un color de texto apropiado según el fondo del tubo
  /// Para tubos oscuros devuelve blanco, para claros devuelve negro
  static Color getTextColorForTubo(String nombreTubo) {
    final backgroundColor = getColorForTubo(nombreTubo);

    // Calcula la luminancia del color de fondo
    final luminance = backgroundColor.computeLuminance();

    // Si el fondo es oscuro (luminance < 0.5), usa texto blanco
    // Si es claro, usa texto negro
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Obtiene una versión más clara del color del tubo (para fondos)
  static Color getLightColorForTubo(String nombreTubo) {
    final baseColor = getColorForTubo(nombreTubo);
    return baseColor.withOpacity(0.15);
  }

  /// Obtiene el icono según el tipo de tubo (personalizable)
  static IconData getIconForTubo(String nombreTubo) {
    // Puedes personalizar iconos específicos por tipo de tubo
    return Icons.science_outlined;
  }
}
