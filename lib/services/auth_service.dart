import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../pantallas/pantalla_bienvenida.dart';
 
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
 
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  final BehaviorSubject<String> _userRole = BehaviorSubject.seeded('user');
 
  Stream<String> get userRoleStream => _userRole.stream;
  User? get currentUser => _auth.currentUser;
 
  // Constructor privado Singleton.
  AuthService._internal() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        // Sin sesión
        _userRole.add('user');
      } else if (user.isAnonymous) {
        // Anónimo: rol 'user' directo, sin tocar la colección users en Firestore
        _userRole.add('user');
        // NO llamamos _updateLastActive para anónimos porque causaría
        // PERMISSION_DENIED al intentar escribir en users/{uid}
      } else {
        // Usuario con email: escuchar rol en Firestore
        _listenToUserRole(user.uid);
        _updateLastActive(user.uid);
      }
    });
  }
 
  // Solo se llama para usuarios NO anónimos
  void _listenToUserRole(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final role = snapshot.data()!['role'] as String? ?? 'user';
              _userRole.add(role);
            } else {
              _userRole.add('user');
            }
          },
          onError: (error) {
            // Si hay error de permisos, degradar silenciosamente a 'user'
            debugPrint('Error escuchando rol: $error');
            _userRole.add('user');
          },
        );
  }
 
  Future<void> _updateLastActive(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Last active actualizado para $userId');
    } catch (e) {
      debugPrint('Error al actualizar last_active: $e');
    }
  }
 
  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      debugPrint('Error al iniciar sesión anónimamente: ${e.code}');
    }
  }
  // Cierra sesión sin navegar ni mostrar nada — para usar antes de un nuevo login
  Future<void> signOutSilently() async {
    try {
      await _auth.signOut();
      _userRole.add('user');
    } catch (e) {
      debugPrint('Error en signOutSilently: $e');
    }
  }
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      _userRole.add('user');
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
 
  String? getCurrentUserId() => _auth.currentUser?.uid;
 
  bool isAnonymous() {
    final user = _auth.currentUser;
    if (user == null) return true;
    return user.isAnonymous;
  }
 
  bool isAuthenticated() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return !user.isAnonymous;
  }
 
  void dispose() {
    _userRole.close();
  }
 
  Future<void> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _updateLastActive(credential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }
 
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }
 
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No se encontró un usuario con ese correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El formato del correo es inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      default:
        return 'Error de credenciales: Revisa tu correo y contraseña.';
    }
  }
}