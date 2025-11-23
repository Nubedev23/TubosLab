import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

class PantallaPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const PantallaPlaceholder({
    required this.title,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Contenido de $title',
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
