import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/activity_provider.dart';

class RegisterExitScreen extends StatefulWidget {
  final String id;  // Necesitamos el id para eliminar
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
  final List<String> estados = ["Completada", "Suspendida", "Cancelada", "Pospuesta"];
  String? _estadoSeleccionado;
  final TextEditingController _resumenController = TextEditingController();
  final String _ubicacion = "Ubicación no obtenida";
  bool _isLoading = false;

  // 📍 Función para registrar la salida y eliminarla
  Future<void> _registrarSalida() async {
    if (_estadoSeleccionado == null || _resumenController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Por favor, complete todos los campos."), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _obtenerUbicacion();

      if (!mounted) return;

      final provider = Provider.of<ActivityProvider>(context, listen: false);

      provider.actualizarEstadoRegistro(widget.id, "salida");

      provider.eliminarActividad(widget.id); // 🔥 Elimina de la lista

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Salida registrada con éxito en Lat: ${position.latitude}, Lng: ${position.longitude}"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);  // 🔥 Regresar al HomeScreen
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al obtener la ubicación: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 📍 Obtener ubicación con manejo de permisos
  Future<Position> _obtenerUbicacion() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("El servicio de ubicación está desactivado.");
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permiso de ubicación denegado.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permisos de ubicación permanentemente denegados.");
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Diligencia'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Registrar Salida",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(widget.imageUrl, height: 120, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Registro de Diligencia:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Estado",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    value: _estadoSeleccionado,
                    items: estados.map((estado) {
                      return DropdownMenuItem(value: estado, child: Text(estado));
                    }).toList(),
                    onChanged: (nuevoEstado) => setState(() => _estadoSeleccionado = nuevoEstado),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _resumenController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Ingrese aquí un resumen...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _ubicacion,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _registrarSalida,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Registrar Salida", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }
}
