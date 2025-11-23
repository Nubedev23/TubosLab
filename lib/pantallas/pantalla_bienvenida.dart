import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'pantalla_principal.dart';
import 'pantalla_admin.dart'; // Importamos la pantalla de admin

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});
  static const routeName = '/bienvenida';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: AppStyles.padding,
          child: Column(
            children: [
              //logo y título
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppStyles.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'TubosLab',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Optimiza la toma de muestras de sangre',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(flex: 1),

              // Cards
              _FeatureCard(
                icon: Icons.search,
                title: 'Iniciar Búsqueda',
                subtitle: 'Accede a la base de datos de exámenes.',
                onTap: () {
                  // Navega a la pantalla principal (que contiene la búsqueda)
                  Navigator.of(context).pushNamed(PantallaPrincipal.routeName);
                },
              ),
              const SizedBox(height: 15),
              _FeatureCard(
                icon: Icons.admin_panel_settings,
                title: 'Soy Administrador',
                subtitle:
                    'Acceso a la configuración de roles y gestión de datos.',
                onTap: () {
                  // Navega a la pantalla de Admin para la auto-asignación de rol
                  Navigator.of(context).pushNamed(PantallaAdmin.routeName);
                },
              ),
              const Spacer(flex: 1),

              const Text(
                'v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppStyles.padding,
        decoration: AppStyles.cardDecoration,
        child: Row(
          children: [
            Icon(icon, size: 30, color: AppStyles.primaryDark),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
