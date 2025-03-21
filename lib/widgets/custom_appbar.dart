import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({super.key, required this.title, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.teal,
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        Consumer<ActivityProvider>(
          builder: (context, provider, child) {
            return Switch(
              value: provider.isOfflineMode,
              onChanged: (value) {
                provider.toggleOfflineMode(value);

                // 🔥 Mostrar mensaje
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value ? "Modo offline activado" : "Modo online activado"),
                    backgroundColor: value ? Colors.orange : Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
