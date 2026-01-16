import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 🔐 Leer token de forma segura
    final storage = SecureStorageService();
    String? token = await storage.getToken();

    // Puedes incluir un pequeño delay para mostrar el splash
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Verificar si la sesión ha expirado
      final isExpired = await storage.isSessionExpired();
      
      if (isExpired) {
        // Sesión expirada, limpiar datos y redirigir al login
        await storage.clearAll();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Sesión válida, actualizar timestamp y redirigir al home
        await storage.saveLastActivityTime();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      // Sino, redirige al LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
