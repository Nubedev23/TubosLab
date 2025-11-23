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

  //Bordes y sombras
  static const double borderRadius = 15.0;
  static const BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    boxShadow: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
  static const EdgeInsets padding = EdgeInsets.all(16.0);
}
