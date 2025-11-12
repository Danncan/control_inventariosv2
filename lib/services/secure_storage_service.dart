import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar almacenamiento seguro y no seguro
/// - Datos sensibles (tokens, contraseñas) → flutter_secure_storage
/// - Datos no sensibles (userId, flags, cache) → SharedPreferences
class SecureStorageService {
  // Instancia única (Singleton)
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Configuración de flutter_secure_storage
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ========== MÉTODOS PARA DATOS SENSIBLES (SEGURO) ==========

  /// Guarda el token JWT de forma segura
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  /// Lee el token JWT de forma segura
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  /// Elimina el token JWT
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  /// Elimina TODOS los datos del almacenamiento seguro
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // ========== MÉTODOS PARA DATOS NO SENSIBLES (SHAREDPREFERENCES) ==========

  /// Guarda el userId (no sensible)
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  /// Lee el userId
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// Guarda el email del usuario (no sensible)
  Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  /// Lee el email del usuario
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  /// Guarda el flag offline
  Future<void> saveOfflineMode(bool isOffline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', isOffline);
  }

  /// Lee el flag offline
  Future<bool> getOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_mode') ?? false;
  }

  /// Guarda actividades en caché
  Future<void> saveActivitiesCache(String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activities_cache', jsonData);
  }

  /// Lee actividades desde caché
  Future<String?> getActivitiesCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activities_cache');
  }

  // ========== MÉTODO PARA LIMPIAR TODO (LOGOUT) ==========

  /// Limpia TODOS los datos (seguro y no seguro)
  Future<void> clearAll() async {
    await clearSecureStorage();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
