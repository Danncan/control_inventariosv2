import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';

class RegisterExitScreen extends StatefulWidget {
  final String id;
  final String title;
  final String imageUrl;

  const RegisterExitScreen({
    super.key,
    required this.id,
    required this.title,
    this.imageUrl = "assets/activityResults.png",
  });

  @override
  State<RegisterExitScreen> createState() => _RegisterExitScreenState();
}

class _RegisterExitScreenState extends State<RegisterExitScreen> {
  final List<String> estados = [
    "Completada",
    "Suspendida",
    "Cancelada",
    "Pospuesta"
  ];
  String? _estadoSeleccionado;
  final TextEditingController _resumenController = TextEditingController();
  String _ubicacion = "Ubicación no obtenida";
  bool _isLoading = false;

  Future<void> _registrarSalida() async {
    if (_estadoSeleccionado == null || _resumenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, complete todos los campos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Obtener ubicación
      final position = await _obtenerUbicacion();
      if (!mounted) return;

      // 2️⃣ Chequea offline antes de llamar al provider
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      final wasOffline = provider.isOffline ||
          await Connectivity().checkConnectivity() == ConnectivityResult.none;

      // 3️⃣ Llamada al provider (crea o encola) con estado y observación
      await provider.registerActivityRecord(
        activityId: widget.id,
        recordType: 'salida',
        position: position,
        activityStatus: _estadoSeleccionado, // 🔥 Envía el estado seleccionado
        observation: _resumenController.text, // 🔥 Envía el resumen/observación
      );

      // 4️⃣ Actualizar estado local y eliminar de la lista
      provider.actualizarEstadoRegistro(widget.id, 'salida');
      provider.eliminarActividad(widget.id);

      // 5️⃣ Mostrar mensaje acorde al modo
      final mensaje = wasOffline
          ? 'Salida registrada en modo offline.'
          : 'Salida registrada con éxito';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: wasOffline ? Colors.orange : Colors.green,
        ),
      );

      // 6️⃣ Volver atrás
      Navigator.pop(context);
    } catch (e) {
      _mostrarAlertaPermisos(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Position> _obtenerUbicacion() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled)
      throw Exception("El servicio de ubicación está desactivado.");

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permiso de ubicación denegado.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Los permisos están permanentemente denegados.");
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  void _mostrarAlertaPermisos(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permisos de Ubicación Requeridos"),
        content: const Text(
          "Para registrar la salida, la aplicación necesita acceso a tu ubicación. "
          "Por favor, ve a los ajustes del dispositivo y habilita los permisos de ubicación.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              Navigator.of(ctx).pop();
            },
            child: const Text("Abrir Ajustes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const CustomAppBar(title: 'Registrar Salida', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset(widget.imageUrl,
                  height: 120, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Registro de Diligencia:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Estado",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    value: _estadoSeleccionado,
                    items: estados
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _estadoSeleccionado = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _resumenController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Ingrese aquí un resumen...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _ubicacion,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _registrarSalida,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Registrar Salida",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
