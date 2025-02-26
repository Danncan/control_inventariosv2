import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ✅ Simulación de API
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    debugPrint("🟢 Intentando login con: $email, $password");

    if (email == "admin@puce.com" && password == "123456") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("email", email);
      await prefs.setString("password", password);

      if (!mounted) return; // ✅ Evita `use_build_context_synchronously`

      setState(() {
        _isLoading = false;
      });

      debugPrint("✅ Login exitoso");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (!mounted) return; // ✅ Evita `use_build_context_synchronously`

      setState(() {
        _isLoading = false;
      });

      debugPrint("❌ Login fallido");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email o contraseña incorrectos."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ Se asegura fondo blanco
      resizeToAvoidBottomInset: true, // ✅ Permite que el teclado no bloquee los inputs
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // ✅ Permite capturar toques y cerrar teclado
        onTap: () {
          FocusScope.of(context).unfocus(); // ✅ Cierra el teclado al tocar fuera
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/PuceLogo.jpg', height: 80),
                  const SizedBox(height: 10),

                  const Text("Bienvenido", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      debugPrint("📝 Email ingresado: $value");
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      debugPrint("📝 Password ingresado: $value");
                    },
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        debugPrint("🔹 Opción '¿Olvidaste tu contraseña?' seleccionada.");
                      },
                      child: const Text("¿Olvidaste tu contraseña?"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            debugPrint("🟢 Botón Login presionado");
                            await _login();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
