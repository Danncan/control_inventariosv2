import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controla en qué paso del flujo nos encontramos (1..4)
  int _step = 1;
  bool _isLoading = false;

  // Controladores de texto
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  // Contador de reenvíos
  int _codeResentCount = 0;

  // URL base de tu API (ajusta según tu caso)
  final String baseUrl = "http://10.0.2.2:3000";

  /// Retorna el texto de instrucciones según el paso
  String get instructionMessage {
    if (_isLoading) {
      return "⏳ Cargando...\nPor favor, espera un momento.";
    }
    switch (_step) {
      case 1:
        return "🔐 Ingresa tu correo para recuperar el acceso a tu cuenta.";
      case 2:
        return "📧 Hemos enviado un código de verificación a tu correo.\n\n*Recuerda que expira en 15 minutos.* ⏳";
      case 3:
        return "🔑 Establece una nueva contraseña.\nPor seguridad, usa una contraseña fuerte.";
      case 4:
        return "Felicidades, tu contraseña ha sido actualizada correctamente. 🎉";
      default:
        return "";
    }
  }

  /// Paso 1: Enviar correo
  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("El correo es obligatorio.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Revisa tu correo para ver el código de verificación.", Colors.green);
        setState(() {
          _step = 2;
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData["message"] ?? "Error desconocido.";
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      _showSnackBar("Ocurrió un error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Reenviar código
  Future<void> _resendEmail() async {
    if (_codeResentCount < 3) {
      _codeResentCount++;
      await _submitEmail();
    } else {
      _showSnackBar("Límite de reenvíos alcanzado. Intenta más tarde.", Colors.red);
    }
  }

  /// Paso 2: Verificar código
  Future<void> _submitCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showSnackBar("El código es obligatorio.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verify-code"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Código verificado, ingresa tu nueva contraseña.", Colors.green);
        setState(() {
          _step = 3;
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData["message"] ?? "Código no válido o expirado.";
        _showSnackBar(errorMsg, Colors.red);

        _codeController.clear();
      }
    } catch (e) {
      _showSnackBar("Ocurrió un error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Paso 3: Cambiar contraseña
  Future<void> _submitResetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (newPassword.isEmpty || repeatPassword.isEmpty) {
      _showSnackBar("Debes ingresar la nueva contraseña.", Colors.red);
      return;
    }
    if (newPassword != repeatPassword) {
      _showSnackBar("Las contraseñas no coinciden.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "code": code,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Tu contraseña ha sido actualizada correctamente!", Colors.green);
        setState(() {
          _step = 4;
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData["message"] ?? "Error al actualizar la contraseña.";
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      _showSnackBar("Ocurrió un error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
      ),
    );
  }

  /// Estilo de los inputs
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  /// Estilo de los botones
  Widget _styledButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    bool outlined = false,
  }) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(text),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(text),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Quitamos el AppBar para usar fondo a pantalla completa
      body: Stack(
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

          // 2) Capa con color + blur (Frosted Glass)
          Container(
          color: Colors.black.withAlpha((0.4 * 255).toInt()),          ),

          // 3) Contenido centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Container(
                // Tarjeta con borde redondeado y algo de transparencia
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.9 * 255).toInt()),                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.2 * 255).toInt()), // Ajuste similar para la sombra
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                width: 400, // Ajusta según tu gusto
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMainContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenido principal dentro de la tarjeta
  Widget _buildMainContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo de PUCE Consultorios Jurídicos (ajusta tu ruta)
        Image.asset(
          "assets/cjpuce.png",
          width: 180,
        ),
        const SizedBox(height: 16),

        // Título
        Text(
          _step == 4 ? "¡Contraseña Actualizada!" : "Recuperar Contraseña",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 16),

        // Mensaje de instrucciones
        Text(
          instructionMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Dependiendo del step, mostramos un formulario diferente
        if (_step == 1) _buildEmailForm(),
        if (_step == 2) _buildCodeForm(),
        if (_step == 3) _buildNewPasswordForm(),
        if (_step == 4) _buildSuccessContent(),
      ],
    );
  }

  /// Paso 1: Formulario de Email
  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration("Correo Electrónico", Icons.email_outlined),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _styledButton(
                text: "Cancelar",
                onPressed: () => Navigator.pop(context),
                outlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _styledButton(
                text: "Enviar",
                onPressed: _submitEmail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Paso 2: Formulario de Código
  Widget _buildCodeForm() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration("Código de Verificación", Icons.verified_user_outlined),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _styledButton(
                text: "Cancelar",
                onPressed: () => Navigator.pop(context),
                outlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _styledButton(
                text: "Verificar Código",
                onPressed: _submitCode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Reenviar código
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("¿No recibiste el código? "),
            GestureDetector(
              onTap: _resendEmail,
              child: const Text(
                "Reenviar",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Paso 3: Formulario de Nueva Contraseña
  Widget _buildNewPasswordForm() {
    return Column(
      children: [
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: _inputDecoration("Nueva Contraseña", Icons.lock_outline),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _repeatPasswordController,
          obscureText: true,
          decoration: _inputDecoration("Confirmar Contraseña", Icons.lock_reset),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _styledButton(
                text: "Cancelar",
                onPressed: () => Navigator.pop(context),
                outlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _styledButton(
                text: "Guardar",
                onPressed: _submitResetPassword,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Paso 4: Éxito
  Widget _buildSuccessContent() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          "¡Tu contraseña ha sido actualizada correctamente!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _styledButton(
          text: "Volver al Inicio",
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
