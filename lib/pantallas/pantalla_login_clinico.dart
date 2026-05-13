import 'package:flutter/material.dart';
import '../utils/app_styles.dart';
import '../services/auth_service.dart';
import 'pantalla_principal.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ← FIX: cerrar sesión previa (admin u anónimo) antes de loguear
      // Esto evita que el rol de admin quede en caché al entrar como clínico
      await _authService.signOutSilently();

      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          PantallaPrincipal.routeName,
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // ← FIX: era "if (!mounted)" — nunca mostraba el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleOlvideContrasena() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo primero para recuperar la contraseña.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de recuperación enviado. Revisa tu bandeja.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
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
              children: [
                const Icon(Icons.badge_outlined, size: 60, color: AppStyles.primaryDark),
                const SizedBox(height: 20),
                Text(
                  'Ingrese sus credenciales',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),

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

                // ← FIX: ahora funciona de verdad con el email del campo
                TextButton(
                  onPressed: _handleOlvideContrasena,
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