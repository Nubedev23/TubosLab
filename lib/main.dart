import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_styles.dart';
import 'pantallas/pantalla_bienvenida.dart';
import 'pantallas/pantalla_principal.dart';
import 'pantallas/pantalla_placeholder.dart';
import 'pantallas/pantalla_detalle_examen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TubosApp());
}

class TubosApp extends StatelessWidget {
  const TubosApp({Key? key}) : super(key: key);

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
        PantallaDetalleExamen.routeName: (context) =>
            const PantallaDetalleExamen(),
      },
    );
  }
}
