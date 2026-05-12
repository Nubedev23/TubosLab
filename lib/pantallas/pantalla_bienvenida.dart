import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import 'pantalla_principal.dart';
import 'pantalla_admin.dart';
import 'pantalla_login_admin.dart';
import '../services/auth_service.dart';
import 'pantalla_login_clinico.dart';

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
                'Optimizando la recolección de muestras de laboratorio',
                textAlign: TextAlign.center,
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
                      // --- TARJETA 1: INICIAR BÚSQUEDA (Público Anónimo) ---
                      _FeatureCard(
                        icon: Icons.search,
                        title: 'Iniciar Búsqueda',
                        subtitle:
                            'Accede a la información de exámenes sin cuenta.',
                        onTap: () {
                          // Se mantiene el login anónimo para satisfacer la regla 'request.auth != null' para lectura
                          _authService.signInAnonymously().then((_) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(PantallaPrincipal.routeName);
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- TARJETA 2: PERSONAL CLÍNICO (Login Email/Pass) ---
                      _FeatureCard(
                        icon: Icons.badge_outlined,
                        title: 'Personal Clínico',
                        subtitle:
                            'Acceso al manual de procedimientos y gestión.',
                        onTap: () {
                          // Navega a la nueva pantalla de login de Personal Clínico
                          Navigator.of(
                            context,
                          ).pushNamed(PantallaLoginClinico.routeName);
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- TARJETA 3: ADMINISTRADOR DINÁMICA (Login Email/Pass) ---
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
                            // Si no es admin, va a la pantalla de login.
                            // Eliminamos el signInAnonymously() redundante aquí.
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
                '© 2025 Tubos App. Desarrollado por MBQ',
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
  // ... (El resto de la clase _FeatureCard no se modifica) ...
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
