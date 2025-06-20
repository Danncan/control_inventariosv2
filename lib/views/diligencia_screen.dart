import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/detail_card.dart';
import '../widgets/custom_bottom_nav.dart';

class DiligenciaScreen extends StatefulWidget {
  final String id;
  final String title;
  final String imageUrl;
  final String location;
  final String date;
  final String time;
  final VoidCallback onEntradaRegistrada;

  const DiligenciaScreen({
    super.key,
    required this.id,
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
  bool _isLoading = false;

  Future<void> _registrarEntrada() async {
    setState(() => _isLoading = true);

    try {
      // 1️⃣ Obtén ubicación
      final position = await _obtenerUbicacion();
      if (!mounted) return;
      setState(() {
        _ubicacion = "Lat: ${position.latitude}, Lng: ${position.longitude}";
      });

      // 2️⃣ Comprueba si estabas offline ANTES de la llamada
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      final wasOffline = provider.isOffline ||
          await Connectivity().checkConnectivity() == ConnectivityResult.none;

      // 3️⃣ Llamada única al provider
      await provider.registerActivityRecord(
        activityId: widget.id,
        recordType: 'entrada',
        position: position,
      );

      // 4️⃣ Mensaje acorde al modo
      final mensaje = wasOffline
          ? 'Entrada registrada en modo offline.'
          : 'Entrada registrada con éxito';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: wasOffline ? Colors.orange : Colors.green,
        ),
      );

      // 5️⃣ Notifica al padre y cierra
      widget.onEntradaRegistrada();
      Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        _mostrarAlertaPermisos(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


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
      throw Exception("Los permisos están permanentemente denegados.");
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  void _mostrarAlertaPermisos(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Permisos de Ubicación Requeridos"),
          content: const Text(
            "Para registrar la entrada, la aplicación necesita acceso a tu ubicación. "
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detallesIzquierda = {
      "Tipo": widget.title,
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset(widget.imageUrl, height: 150, fit: BoxFit.contain),
            const SizedBox(height: 20),
            DetailCard(
              leftDetails: detallesIzquierda,
              rightDetails: detallesDerecha,
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _registrarEntrada,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Registrar Entrada",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
