import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/detail_card.dart';

class DiligenciaScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Map<String, String> detallesIzquierda = {
      "Tipo": "Juicio de Alimentos",
      "Ubicación": location,
      "Fecha": date,
      "Hora": time,
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
      body: SingleChildScrollView( // 🔥 Permite desplazamiento si hay overflow
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 🔥 Centra el contenido verticalmente
            crossAxisAlignment: CrossAxisAlignment.center, // 🔥 Centra el contenido horizontalmente
            children: [
              const Text(
                "Registrar Entrada:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Imagen de la actividad
              Center(
                child: Image.asset(
                  imageUrl,
                  height: 160, // 🔥 Aumenté el tamaño de la imagen
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // Tarjeta con los detalles de la actividad
              DetailCard(leftDetails: detallesIzquierda, rightDetails: detallesDerecha),
              const SizedBox(height: 40),

              // Botón de Registrar Entrada
              ElevatedButton(
                onPressed: () {
                  // Acción para registrar la entrada
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
              const SizedBox(height: 40), // 🔥 Añadimos espacio al final para que se vea mejor
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendario"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Actividades"),
          BottomNavigationBarItem(icon: Icon(Icons.label), label: "Label"),
        ],
      ),
    );
  }
}
