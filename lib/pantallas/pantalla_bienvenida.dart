import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'pantalla_principal.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({Key? key}) : super(key: key);
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

              //Cards
              _FeatureCard(
                icon: Icons.flash_on,
                title: 'Optimización Inteligente',
                subtitle:
                    'Agrega exámenes a tu carrito y obtén el núemero exacto de tubos necesarios',
                onTap: () {},
              ),
              const SizedBox(height: 15),
              _FeatureCard(
                icon: Icons.description_outlined,
                title: 'Manual digital',
                subtitle: 'Acceda a los protocolos de toma de muestras',
                onTap: () {},
              ),
              const SizedBox(height: 15),
              _FeatureCard(
                icon: Icons.bar_chart,
                title: 'Estadísticas de uso',
                subtitle:
                    'Monitorea exámenes más consultados, métricas e historial',
                onTap: () {},
              ),
              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(PantallaPrincipal.routeName);
                  },
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  label: const Text(
                    'Comenzar',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppStyles.borderRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
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
