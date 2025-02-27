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
  final VoidCallback onEntradaRegistrada; // 👈 Agregado este parámetro

  const DiligenciaScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.time,
    required this.onEntradaRegistrada, // 👈 Y acá también
  });

  @override
  DiligenciaScreenState createState() => DiligenciaScreenState();
}

class DiligenciaScreenState extends State<DiligenciaScreen> {
  String _ubicacion = "Ubicación no obtenida";

  Future<void> _obtenerUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _ubicacion = "El servicio de ubicación está desactivado.";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
        _ubicacion = "Permisos de ubicación permanentemente denegados.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _ubicacion = "Lat: ${position.latitude}, Lng: ${position.longitude}";
    });

    debugPrint("Ubicación obtenida: $_ubicacion");
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
            Text(
              _ubicacion,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _obtenerUbicacion();

                if (!mounted) return;  // 🔥 Importante: Protege de cambios después de dispose

                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Entrada registrada con éxito."),
                      backgroundColor: Colors.green,
                    ),
                  );

                  widget.onEntradaRegistrada();

                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);  // 🔥 Solo si sigue montado, regresa al home
                }
              },
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
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}