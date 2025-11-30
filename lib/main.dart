import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_styles.dart';
import 'pantallas/pantalla_bienvenida.dart';
import 'pantallas/pantalla_principal.dart';
import 'pantallas/pantalla_placeholder.dart';
import 'pantallas/pantalla_detalle_examen.dart';
import 'pantallas/pantalla_busqueda.dart';
import 'pantallas/pantalla_admin.dart';
import 'pantallas/pantalla_gestion_examen.dart';
import 'pantallas/pantalla_login_admin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TubosApp());
}

class TubosApp extends StatelessWidget {
  const TubosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tubos App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppStyles.primaryDark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppStyles.primaryDark),
        useMaterial3: true,

        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
        ),
      ),
      initialRoute: PantallaBienvenida.routeName,
      routes: {
        PantallaBienvenida.routeName: (context) => const PantallaBienvenida(),
        PantallaPrincipal.routeName: (context) => const PantallaPrincipal(),
        // Las pantallas Placeholder no se usan como ruta de navegación, se usan dentro de PantallaPrincipal
        PantallaDetalleExamen.routeName: (context) =>
            const PantallaDetalleExamen(),
        PantallaBusqueda.routeName: (context) => const PantallaBusqueda(),
        PantallaAdmin.routeName: (context) => const PantallaAdmin(),
        PantallaLoginAdmin.routeName: (context) => const PantallaLoginAdmin(),
        PantallaGestionExamen.routeName: (context) {
          final examenId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return PantallaGestionExamen(examenId: examenId);
        },
        // Ruta de atajo para /admin
        '/admin': (context) => const PantallaAdmin(),
      },
    );
  }
}
