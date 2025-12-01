import 'package:flutter/material.dart';
import 'pantalla_busqueda.dart';
import 'pantalla_placeholder.dart';
import '../services/auth_service.dart';
import '../services/carrito_service.dart'; // Importar el servicio de carrito
import 'pantalla_gestion_examen.dart';
import 'pantalla_carrito.dart'; // Importar la pantalla de carrito
import '../models/examen.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});
  static const routeName = '/main';

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;
  // Instancia del servicio de autenticación (usa el constructor factory)
  final AuthService _authService = AuthService();
  final CarritoService _carritoService = CarritoService();
  final List<Widget> _pantallas = [
    const PantallaBusqueda(),
    const PantallaPlaceholder(
      title: 'Manual digital',
      icon: Icons.book_outlined,
    ),
    const PantallaPlaceholder(
      title: 'Estadísticas de Uso',
      icon: Icons.bar_chart_outlined,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Widget para construir el AppBar, que cambia según el rol.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('TubosLab'),
      actions: <Widget>[
        ValueListenableBuilder<List<Examen>>(
          valueListenable: _carritoService.examenesEnCarritoListenable,
          builder: (context, examenes, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'Ver Carrito',
                  onPressed: () {
                    Navigator.of(context).pushNamed(PantallaCarrito.routeName);
                  },
                ),
                if (examenes.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${examenes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // 1. Mostrar el botón de Gestión de Exámenes (CRUD)
        StreamBuilder<String>(
          stream: _authService.userRoleStream,
          initialData: 'user', // Asume 'user' hasta que se cargue
          builder: (context, snapshot) {
            final role = snapshot.data;
            // Solo si el rol es 'admin', muestra el botón de gestión
            if (role == 'admin') {
              return IconButton(
                icon: const Icon(Icons.edit_note),
                tooltip: 'Gestionar Exámenes',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(PantallaGestionExamen.routeName);
                },
              );
            }
            return const SizedBox.shrink(); // Widget vacío si no es admin
          },
        ),
        // 2. Botón de Cerrar Sesión
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: () {
            // Llamada con el argumento 'context'
            _authService.signOut(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _pantallas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Manual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.area_chart_outlined),
            label: 'Estadísticas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF212121),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
