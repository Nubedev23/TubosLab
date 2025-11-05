import 'package:flutter/material.dart';
import 'pantalla_busqueda.dart';
import 'pantalla_placeholder.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({Key? key}) : super(key: key);
  static const routeName = '/main';

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
