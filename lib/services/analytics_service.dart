import 'package:firebase_analytics/firebase_analytics.dart'; // ✅ COMILLA CORREGIDA
import 'package:flutter/foundation.dart';

class AnalyticsService {
  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Obtiene el observer para navegación (para usar en MaterialApp)
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ============================================
  // EVENTOS DE BÚSQUEDA
  // ============================================

  /// Registra cuando un usuario busca un examen
  Future<void> logBusquedaExamen(String terminoBusqueda) async {
    await _analytics.logSearch(searchTerm: terminoBusqueda);
    debugPrint('Analytics: Búsqueda registrada - "$terminoBusqueda"');
  }

  /// Registra cuando se visualiza el detalle de un examen
  Future<void> logVistaDetalleExamen(
    String examenId,
    String nombreExamen,
  ) async {
    //  CORREGIDO: logViewItem no acepta itemId en esta versión
    await _analytics.logEvent(
      name: 'view_item',
      parameters: {
        'item_id': examenId,
        'item_name': nombreExamen,
        'item_category': 'examen',
      },
    );
    debugPrint('Analytics: Vista de examen - "$nombreExamen"');
  }

  // ============================================
  // EVENTOS DE CARRITO
  // ============================================

  /// Registra cuando se agrega un examen al carrito
  Future<void> logAgregarAlCarrito(String examenId, String nombreExamen) async {
    // CORREGIDO: logAddToCart tampoco acepta itemId directamente
    await _analytics.logEvent(
      name: 'add_to_cart',
      parameters: {
        'item_id': examenId,
        'item_name': nombreExamen,
        'item_category': 'examen',
        'quantity': 1,
      },
    );
    debugPrint('Analytics: Agregado al carrito - "$nombreExamen"');
  }

  /// Registra cuando se remueve un examen del carrito
  Future<void> logRemoverDelCarrito(
    String examenId,
    String nombreExamen,
  ) async {
    //CORREGIDO
    await _analytics.logEvent(
      name: 'remove_from_cart',
      parameters: {
        'item_id': examenId,
        'item_name': nombreExamen,
        'item_category': 'examen',
        'quantity': 1,
      },
    );
    debugPrint('Analytics: Removido del carrito - "$nombreExamen"');
  }

  /// Registra cuando se procesa una solicitud (checkout)
  Future<void> logProcesarSolicitud(
    int cantidadExamenes,
    List<String> tiposTubos,
  ) async {
    await _analytics.logEvent(
      name: 'procesar_solicitud',
      parameters: {
        'cantidad_examenes': cantidadExamenes,
        'cantidad_tubos': tiposTubos.length,
        'tipos_tubos': tiposTubos.join(','),
      },
    );
    debugPrint('Analytics: Solicitud procesada - $cantidadExamenes exámenes');
  }

  // ============================================
  // EVENTOS DE AUTENTICACIÓN
  // ============================================

  /// Registra el login de un usuario
  Future<void> logLogin(String metodo) async {
    await _analytics.logLogin(loginMethod: metodo);
    debugPrint('Analytics: Login registrado - $metodo');
  }

  /// Registra cuando un usuario cierra sesión
  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    debugPrint('Analytics: Logout registrado');
  }

  // ============================================
  // EVENTOS DE ADMINISTRACIÓN
  // ============================================

  /// Registra cuando se crea un nuevo examen
  Future<void> logCrearExamen(String nombreExamen) async {
    await _analytics.logEvent(
      name: 'crear_examen',
      parameters: {'nombre': nombreExamen},
    );
    debugPrint('Analytics: Examen creado - "$nombreExamen"');
  }

  /// Registra cuando se edita un examen
  Future<void> logEditarExamen(String examenId, String nombreExamen) async {
    await _analytics.logEvent(
      name: 'editar_examen',
      parameters: {'examen_id': examenId, 'nombre': nombreExamen},
    );
    debugPrint('Analytics: Examen editado - "$nombreExamen"');
  }

  /// Registra cuando se elimina un examen
  Future<void> logEliminarExamen(String examenId, String nombreExamen) async {
    await _analytics.logEvent(
      name: 'eliminar_examen',
      parameters: {'examen_id': examenId, 'nombre': nombreExamen},
    );
    debugPrint('Analytics: Examen eliminado - "$nombreExamen"');
  }

  // ============================================
  // EVENTOS DE MANUAL PDF
  // ============================================

  /// Registra cuando se abre el manual PDF
  Future<void> logAbrirManual() async {
    await _analytics.logEvent(name: 'abrir_manual_pdf');
    debugPrint('Analytics: Manual PDF abierto');
  }

  // ============================================
  // PROPIEDADES DE USUARIO
  // ============================================

  /// Establece el rol del usuario actual
  Future<void> setUserRole(String role) async {
    await _analytics.setUserProperty(name: 'user_role', value: role);
    debugPrint('Analytics: Rol de usuario establecido - $role');
  }

  // ============================================
  // EVENTO PERSONALIZADO GENÉRICO
  // ============================================

  /// Registra un evento personalizado
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters, //  CORREGIDO: Object en lugar de dynamic
  }) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
    debugPrint('Analytics: Evento personalizado - $eventName');
  }
}
