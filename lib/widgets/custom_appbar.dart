import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/login_screen.dart';
import '../providers/activity_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _toggleOffline(BuildContext context) async {
    final provider = Provider.of<ActivityProvider>(context, listen: false);

    // 1) Mostrar diálogo bloqueante
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 2) Ejecutar toggle (fetch+cache o sync según el nuevo estado)
    await provider.toggleOfflineMode();

    // 3) Cerrar diálogo
    if (context.mounted) Navigator.of(context).pop();

    // 4) Mostrar mensaje
    final mensaje = provider.isOffline
        ? 'Modo offline activado: actividades cacheadas'
        : 'Modo online: sincronizando pendientes';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, _) {
        return AppBar(
          backgroundColor: Colors.teal,
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          actions: [
            // Toggle offline
            IconButton(
              icon: Icon(
                provider.isOffline ? Icons.cloud_off : Icons.cloud_queue,
                color: provider.isOffline ? Colors.red : Colors.white,
              ),
              onPressed: () => _toggleOffline(context),
            ),
            // Logout
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _logout(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
