import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/activity_provider.dart';
import 'views/splash_screen.dart'; // Importa la nueva pantalla de splash

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Actividades',
      theme: ThemeData(primarySwatch: Colors.teal),
      home:
          const SplashScreen(), // Arranca en SplashScreen para verificar el login
    );
  }
}
