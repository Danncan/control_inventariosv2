import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';  // <-- nuevo


import 'forgotpasword_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Para utilizar la aplicación necesitas Internet."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);  
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validaciones mínimas
    if (email.isEmpty || password.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingrese su correo y contraseña."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Petición al servidor
    final url = Uri.parse("http://192.168.18.117:3000/login"); // Ajusta tu URL real
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "Internal_Email": email,
          "Internal_Password": password,
        }),
      );

      if (response.statusCode == 200) {
        // Éxito en la petición
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        if (token == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se recibió token del servidor."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        print( "Token recibido: $token");
        // Decodificar token
        final decodedToken = JwtDecoder.decode(token);
        final userId = decodedToken["id"];
        final userEmail = decodedToken["email"];
        print("Token decodificado: $decodedToken");
        print("ID de usuario: $userId");
        print("Email de usuario: $userEmail");
        // Guardar token y datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        if (userId != null) {
          await prefs.setString("userId", userId.toString());
        }
        if (userEmail != null) {
          await prefs.setString("userEmail", userEmail);
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Navegar a Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Error en el statusCode
        debugPrint("Status code: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");

        String errorMessage = "Error desconocido en el login.";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {
          // Body no es JSON
          errorMessage = response.body;
        }

        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      // Error de conexión o excepción
      debugPrint("❌ Error en la petición de login: $error");
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ocurrió un error: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar teclado al tocar fuera de los TextFields
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1) Imagen de fondo
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/puce.jpg"), // Ajusta tu ruta
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 2) Capa con color + transparencia (oscurece el fondo)
            Container(
              color: Colors.black.withOpacity(0.4),
            ),

            // 3) Contenido centrado (tarjeta)
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Container(
                  width: 380, // Ajusta a tu gusto
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildLoginContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Separa el contenido del login para mantener orden
  Widget _buildLoginContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo PUCE (ajusta la ruta según tus assets)
        Image.asset(
          'assets/cjpuce.png',
          height: 80,
        ),
        const SizedBox(height: 16),

        // Título
        const Text(
          "Bienvenido",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 20),

        // Campo Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 16),

        // Campo Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade100,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ¿Olvidaste tu contraseña?
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              debugPrint("🔹 Opción '¿Olvidaste tu contraseña?' seleccionada.");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              );
            },
            child: const Text("¿Olvidaste tu contraseña?"),
          ),
        ),
        const SizedBox(height: 12),

        // Botón de Login
        ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
