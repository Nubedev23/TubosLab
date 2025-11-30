import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantalla_admin.dart';

class PantallaLoginAdmin extends StatefulWidget {
  const PantallaLoginAdmin({super.key});

  static const routeName = '/login-admin';

  @override
  State<PantallaLoginAdmin> createState() => _PantallaLoginAdminState();
}

class _PantallaLoginAdminState extends State<PantallaLoginAdmin> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  final FirestoreService _fs = FirestoreService();

  final String adminUser = "admin";
  final String adminPass = "12345";

  bool loading = false;
  String? errorMsg;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso Administrador")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: "Usuario"),
            ),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 20),

            if (errorMsg != null)
              Text(errorMsg!, style: const TextStyle(color: Colors.red)),

            ElevatedButton(
              onPressed: loading ? null : _loginAdmin,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginAdmin() async {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (user != adminUser || pass != adminPass) {
      setState(() => errorMsg = "Credenciales incorrectas");
      return;
    }

    setState(() {
      loading = true;
      errorMsg = null;
    });

    final userAuth = FirebaseAuth.instance.currentUser;
    if (userAuth == null) {
      setState(() {
        loading = false;
        errorMsg = "No hay usuario logueado en Firebase Auth.";
      });
      return;
    }

    await _fs.setUserRole(userAuth.uid, "admin");

    if (mounted) {
      setState(() {
        loading = false;
      });

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(PantallaAdmin.routeName, (route) => false);
    }
  }
}
