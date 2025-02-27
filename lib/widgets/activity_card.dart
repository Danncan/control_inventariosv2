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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.asset(
              imageUrl,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 80,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                _buildDetail("Ubicación", location),
                _buildDetail("Fecha", date),
                _buildDetail("Hora", time),
                const SizedBox(height: 8),

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
                    child: const Text(
                      "Ver más",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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

    DateTime activityDate = DateFormat("dd-MMM-yyyy").parse(date);
    DateTime now = DateTime.now();

    DateTime activityTime = DateFormat("HH:mm").parse(time);
    DateTime nowTime = DateFormat("HH:mm").parse("${now.hour}:${now.minute}");

    bool esHoy = activityDate.year == now.year && activityDate.month == now.month && activityDate.day == now.day;
    bool esHoraPermitida = nowTime.isAfter(activityTime) || nowTime.isAtSameMomentAs(activityTime);

    String estado = provider.obtenerEstadoRegistro(id);

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
          content: Text("No puedes registrar la entrada antes de la hora programada."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (estado == "entrada") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterExitScreen(title: title, id: id,),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiligenciaScreen(
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
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
