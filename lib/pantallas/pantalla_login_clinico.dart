// lib/pantallas/pantalla_login_clinico.dart

import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/auth_service.dart';
import 'pantalla_principal.dart'; // Para redirigir

class PantallaLoginClinico extends StatefulWidget {
  const PantallaLoginClinico({super.key});

  static const routeName = '/login-clinico';

  @override
  State<PantallaLoginClinico> createState() => _PantallaLoginClinicoState();
}

class _PantallaLoginClinicoState extends State<PantallaLoginClinico> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Llamada al nuevo método signIn de AuthService
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Si el login es exitoso, redirigir a la pantalla principal
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            PantallaPrincipal.routeName,
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        // Mostrar error en caso de fallo de autenticación
        if (!mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso personal clínico'),
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
              children: <Widget>[
                const Icon(
                  Icons.badge_outlined,
                  size: 60,
                  color: AppStyles.primaryDark,
                ),
                const SizedBox(height: 20),
                Text(
                  'Ingrese sus credenciales',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),

                // Campo de Correo Electrónico
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
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
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su contraseña.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Botón de Inicio de Sesión
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: AppStyles.cardShape,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 20),

                // Opción Olvidé mi Contraseña
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Funcionalidad de recuperación de contraseña pendiente.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Olvidé mi Contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
