import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/detail_card.dart';
import '../widgets/custom_bottom_nav.dart';

class DiligenciaScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String location;
  final String date;
  final String time;
  final VoidCallback onEntradaRegistrada; // 👈 Se ejecuta cuando se registra la entrada

  const DiligenciaScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.time,
    required this.onEntradaRegistrada,
  });

  @override
  DiligenciaScreenState createState() => DiligenciaScreenState();
}

class DiligenciaScreenState extends State<DiligenciaScreen> {
  String _ubicacion = "Ubicación no obtenida";
  bool _isLoading = false; // 🔄 Estado de carga

  Future<void> _registrarEntrada() async {
    setState(() {
      _isLoading = true; // 🔄 Mostrar loader
    });

    try {
      final position = await _obtenerUbicacion();

      if (!mounted) return;

      setState(() {
        _ubicacion = "Lat: ${position.latitude}, Lng: ${position.longitude}";
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entrada registrada con éxito."),
            backgroundColor: Colors.green,
          ),
        );
        widget.onEntradaRegistrada();
        Navigator.pop(context); // 🔥 Regresa al HomeScreen
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ubicacion = "Error: $e";
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al obtener la ubicación: $e"),
            backgroundColor: Colors.red,
          ),
        );
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
    final detallesIzquierda = {
      "Tipo": "Juicio de Alimentos",
      "Ubicación": widget.location,
      "Fecha": widget.date,
      "Hora": widget.time,
      "Abogado Asignado": "Dr. Juan Pérez",
    };

    final detallesDerecha = {
      "Duración Estimada": "2 horas",
      "Referencia del Expediente": "2025-AL-00789",
      "Contraparte": "María Gómez",
      "Juez Asignado": "Dra. Ana Velasco",
    };

    return Scaffold(
      appBar: const CustomAppBar(title: 'Diligencia', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Registrar Entrada:",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset(widget.imageUrl, height: 150, fit: BoxFit.contain),
            const SizedBox(height: 20),
            DetailCard(leftDetails: detallesIzquierda, rightDetails: detallesDerecha),
            const SizedBox(height: 20),

            // 📍 Mostrar la ubicación obtenida
            Text(
              _ubicacion,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // 🔘 Botón de "Registrar Entrada" con loader
            ElevatedButton(
              onPressed: _isLoading ? null : _registrarEntrada,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white) // 🔄 Loader mientras obtiene ubicación
                  : const Text(
                      "Registrar Entrada",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}