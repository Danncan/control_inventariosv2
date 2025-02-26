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

  const DiligenciaScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.time,
  });

  @override
  DiligenciaScreenState createState() => DiligenciaScreenState();
}

class DiligenciaScreenState extends State<DiligenciaScreen> {
  String _ubicacion = "Ubicación no obtenida";

  // 🔥 Función para obtener la ubicación
  Future<void> _obtenerUbicacion() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1️⃣ Verifica si el servicio de ubicación está activado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _ubicacion = "El servicio de ubicación está desactivado.";
      });
      return;
    }

    // 2️⃣ Verifica y solicita permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _ubicacion = "Permiso de ubicación denegado.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _ubicacion = "Los permisos de ubicación están permanentemente denegados.";
      });
      return;
    }

    // 3️⃣ Obtener ubicación actual (🔥 Usando `locationSettings` en lugar de `desiredAccuracy`)
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    setState(() {
      _ubicacion = "Lat: ${position.latitude}, Lng: ${position.longitude}";
    });

    // 🔥 Ahora usamos `debugPrint()` en lugar de `print()`
    debugPrint("Ubicación obtenida: $_ubicacion");
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> detallesIzquierda = {
      "Tipo": "Juicio de Alimentos",
      "Ubicación": widget.location,
      "Fecha": widget.date,
      "Hora": widget.time,
      "Abogado Asignado": "Dr. Juan Pérez",
    };

    final Map<String, String> detallesDerecha = {
      "Duración Estimada": "2 horas",
      "Referencia del Expediente": "2025-AL-00789",
      "Contraparte": "María Gómez",
      "Juez Asignado": "Dra. Ana Velasco",
    };

    return Scaffold(
      appBar: const CustomAppBar(title: 'Diligencia', showBackButton: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Registrar Entrada:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Imagen de la actividad
              Center(
                child: Image.asset(
                  widget.imageUrl,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Tarjeta con los detalles de la actividad
              DetailCard(leftDetails: detallesIzquierda, rightDetails: detallesDerecha),
              const SizedBox(height: 20),

              // Mostrar ubicación obtenida
              Text(
                _ubicacion,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Botón de Registrar Entrada (Obtiene la ubicación)
              ElevatedButton(
                onPressed: _obtenerUbicacion, // 🔥 Llamar la función de ubicación
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Registrar Entrada",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
       bottomNavigationBar: const CustomBottomNav(currentIndex: 1),

    );
  }
}
