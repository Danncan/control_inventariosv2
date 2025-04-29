import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../views/diligencia_screen.dart';
import '../views/register_exit_screen.dart';
import '../providers/activity_provider.dart';

class ActivityCard extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final String location;
  final String date;
  final String time;

  const ActivityCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.location,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              imageUrl,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
              ),
            ),
          ),
          // Detalles
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                _buildDetail("Ubicación", location),
                _buildDetail("Fecha", date),
                _buildDetail("Hora", time),
                const SizedBox(height: 8),
                // Botón
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () => _verificarAcceso(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Ver más", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _verificarAcceso(BuildContext context) {
    final provider = Provider.of<ActivityProvider>(context, listen: false);

    // Parseo de fecha y hora
    final activityDate = DateFormat("dd-MMM-yyyy").parse(date);
    final now = DateTime.now();
    final activityTime = DateFormat("HH:mm").parse(time);
    final nowTime = DateFormat("HH:mm").parse("${now.hour}:${now.minute}");

    // Validaciones
    final esHoy = activityDate.year == now.year &&
        activityDate.month == now.month &&
        activityDate.day == now.day;
    final esHoraPermitida =
        nowTime.isAfter(activityTime) || nowTime.isAtSameMomentAs(activityTime);
    final limite = activityTime.add(const Duration(minutes: 30));
    final fueraDeTiempo = nowTime.isAfter(limite);

    final estado = provider.obtenerEstadoRegistro(id);

    if (!esHoy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Solo puedes acceder a actividades del día de hoy."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!esHoraPermitida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("No puedes registrar la entrada antes de la hora programada."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (fueraDeTiempo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "No puedes registrar la entrada. Han pasado más de 30 minutos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navegación según estado
    if (estado == "entrada") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterExitScreen(id: id, title: title),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiligenciaScreen(
            id: id,
            title: title,
            imageUrl: imageUrl,
            location: location,
            date: date,
            time: time,
            onEntradaRegistrada: () {
              provider.actualizarEstadoRegistro(id, "entrada");
            },
          ),
        ),
      );
    }
  }

  Widget _buildDetail(String label, String value) {
    return RichText(
      text: TextSpan(
        text: "$label: ",
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.grey,
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}
