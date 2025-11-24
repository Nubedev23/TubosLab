import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'pantalla_principal.dart';
import 'pantalla_admin.dart';
import 'pantalla_login_admin.dart';
import '../services/auth_service.dart';

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});
  static const routeName = '/bienvenida';

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  // 1. Obtener la instancia del Singleton de AuthService
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: AppStyles.padding,
          child: Column(
            children: [
              // logo y título
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

              // Contenido principal (Tarjetas)
              // 2. Usamos StreamBuilder para escuchar el rol en tiempo real
              StreamBuilder<String>(
                stream: _authService.userRoleStream,
                initialData: 'user', // Valor inicial para evitar null
                builder: (context, snapshot) {
                  final currentRole = snapshot.data;
                  final isAdmin = currentRole == 'admin';

                  return Column(
                    children: [
                      // --- TARJETA 1: INICIAR BÚSQUEDA ---
                      _FeatureCard(
                        icon: Icons.search,
                        title: 'Iniciar Búsqueda',
                        subtitle:
                            'Accede a la información de tubos sin cuenta.',
                        onTap: () {
                          // Inicia sesión anónima (si no lo estás) y navega.
                          _authService.signInAnonymously().then((_) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(PantallaPrincipal.routeName);
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- TARJETA 2: ADMINISTRADOR DINÁMICA ---
                      _FeatureCard(
                        // Icono dinámico
                        icon: isAdmin ? Icons.settings : Icons.login,
                        // Título dinámico
                        title: isAdmin
                            ? 'Panel de Administrador'
                            : 'Soy Administrador',
                        // Subtítulo dinámico
                        subtitle: isAdmin
                            ? 'Gestiona exámenes. Rol actual: ADMIN.'
                            : 'Acceso para gestión de contenidos.',
                        onTap: () async {
                          if (isAdmin) {
                            // Si ya es admin, va directo al panel
                            Navigator.of(
                              context,
                            ).pushNamed(PantallaAdmin.routeName);
                          } else {
                            //iniciar sesión como anonimamente
                            await _authService.signInAnonymously();

                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).pushNamed(PantallaLoginAdmin.routeName);
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),

              const Spacer(flex: 2),
              const Text(
                '© 2024 Tubos App. Desarrollado por [Tu Nombre]',
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

// Clase auxiliar (se mantiene sin cambios)
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
