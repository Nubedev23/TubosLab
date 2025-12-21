import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importamos el AuthService
import '../utils/app_styles.dart'; // Para estilos
import 'pantalla_principal.dart'; // Para redirigir
import 'pantalla_admin.dart'; // Para redirigir

class PantallaLoginAdmin extends StatefulWidget {
  const PantallaLoginAdmin({super.key});

  static const routeName = '/login-admin';

  @override
  State<PantallaLoginAdmin> createState() => _PantallaLoginAdminState();
}

class _PantallaLoginAdminState extends State<PantallaLoginAdmin> {
  // Usaremos el AuthService que contiene el método signIn()
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Cambiamos 'Usuario' a 'Email' para alinearlo con Firebase Auth
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      try {
        // *** 1. USAR FIREBASE AUTH PARA INICIAR SESIÓN ***
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Si el login es exitoso, Firebase ahora tiene el usuario autenticado.
        // El stream de roles en AuthService se actualizará automáticamente.

        // ** 2. REDIRIGIR **
        // Redirigimos directamente al panel de administrador, ya que solo los admins
        // que logren pasar este paso y tengan el rol en Firestore podrán acceder.
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            PantallaAdmin.routeName,
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        // Manejar errores de Firebase (contraseña incorrecta, usuario no existe, etc.)
        if (!mounted) return;
        final mensaje = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de inicio de sesión: $mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
    //       setState(() {
    //         // Muestra el mensaje de error útil devuelto por _authService.signIn()
    //         _errorMsg = e.toString().replaceFirst('Exception: ', '');
    //       });
    //     }
    //   } finally {
    //     if (mounted) {
    //       setState(() {
    //         _isLoading = false;
    //       });
    //     }
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Acceso Administrador"),
        backgroundColor: AppStyles.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppStyles.padding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 60,
                  color: AppStyles.primaryDark,
                ),
                const SizedBox(height: 20),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo de Administrador',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su correo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su contraseña.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      _errorMsg!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Botón de Inicio de Sesión
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: AppStyles.cardShape,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Ingresar al Panel",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
