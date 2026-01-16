import 'dart:async';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import '../views/login_screen.dart';

/// Servicio para gestionar la sesión del usuario
/// Verifica automáticamente la expiración de la sesión cada minuto
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final _storage = SecureStorageService();
  Timer? _sessionTimer;
  BuildContext? _context;

  /// Inicializa el temporizador de sesión
  void startSessionTimer(BuildContext context) {
    _context = context;
    
    // Actualizar timestamp al iniciar
    _storage.saveLastActivityTime();

    // Verificar sesión cada minuto
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkSession();
    });
  }

  /// Actualiza el timestamp de la última actividad
  Future<void> updateActivity() async {
    await _storage.saveLastActivityTime();
  }

  /// Verifica si la sesión ha expirado
  Future<void> _checkSession() async {
    final isExpired = await _storage.isSessionExpired();
    
    if (isExpired) {
      await logout();
    }
  }

  /// Cierra sesión y redirige al login
  Future<void> logout() async {
    _sessionTimer?.cancel();
    await _storage.clearAll();

    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Detiene el temporizador de sesión
  void stopSessionTimer() {
    _sessionTimer?.cancel();
  }

  /// Verifica la sesión manualmente
  Future<bool> checkSessionValidity() async {
    return !(await _storage.isSessionExpired());
  }
}
