import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../pantallas/pantalla_bienvenida.dart';

class AuthService {
  // Instancia Singleton: asegura que solo exista una instancia de esta clase.
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // BehaviorSubject para almacenar y transmitir el rol actual del usuario.
  // Inicia con 'user' por defecto hasta que se compruebe el rol.
  final BehaviorSubject<String> _userRole = BehaviorSubject.seeded('user');

  // Getter público para que los Widgets escuchen los cambios de rol.
  Stream<String> get userRoleStream => _userRole.stream;

  // Constructor privado Singleton.
  AuthService._internal() {
    // Inicializa la escucha de cambios de autenticación.
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // No hay usuario logueado. Reiniciar el rol a 'user'.
        _userRole.add('user');
      } else {
        // Usuario logueado. Iniciar la obtención del rol desde Firestore.
        _listenToUserRole(user.uid);
      }
    });
  }

  // Método para obtener el rol del usuario desde Firestore en tiempo real.
  void _listenToUserRole(String userId) {
    // Escucha el documento de usuario para cambios en el campo 'role'.
    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final role = data['role'] as String? ?? 'user';
        _userRole.add(role); // Actualiza el stream con el rol encontrado.
      } else {
        _userRole.add(
          'user',
        ); // Si no existe el documento o rol, es un usuario regular.
      }
    });
  }

  // Método para iniciar sesión de forma anónima
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al iniciar sesión anónimamente: ${e.code}');
    }
  }

  // Método para cerrar sesión. Requiere el contexto para la navegación.
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Limpia el rol en el stream.
      _userRole.add('user');
      // Redirige a la pantalla de bienvenida.
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          PantallaBienvenida.routeName,
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // Método para obtener el ID de usuario actual (puede ser null).
  String? getCurrentUserId() => _auth.currentUser?.uid;

  void dispose() {
    _userRole.close();
  }
}
