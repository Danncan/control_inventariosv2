import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../views/diligencia_screen.dart';
import '../views/register_exit_screen.dart';

class ActivityListScreen extends StatelessWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Listado de Actividades'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<ActivityProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.activities.isEmpty) {
              return const Center(
                child: Text("No hay actividades disponibles.",
                    style: TextStyle(fontSize: 16)),
              );
            }

            return ListView.builder(
              itemCount: provider.activities.length,
              itemBuilder: (context, index) {
                final activity = provider.activities[index];

                // 🔹 Convertir fechas y horas
                DateTime activityDate =
                    DateFormat("dd-MMM-yyyy").parse(activity['date']);
                DateTime now = DateTime.now();
                DateTime activityTime =
                    DateFormat("HH:mm").parse(activity['time']);
                DateTime nowTime =
                    DateFormat("HH:mm").parse("${now.hour}:${now.minute}");

                // 🔹 Validaciones
                bool esHoy = activityDate.year == now.year &&
                    activityDate.month == now.month &&
                    activityDate.day == now.day;
                bool esHoraPermitida = nowTime.isAfter(
                        activityTime.subtract(const Duration(minutes: 30))) &&
                    nowTime.isBefore(
                        activityTime.add(const Duration(minutes: 30)));
                String estado = provider.obtenerEstadoRegistro(activity['id']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          activity['imageUrl']!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported,
                                  size: 30),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        activity['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 ${activity['location']}"),
                          Text(
                              "📅 ${activity['date']} - 🕒 ${activity['time']}"),
                        ],
                      ),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.arrow_forward, color: Colors.teal),
                        onPressed: () {
                          if (!esHoy) {
                            _mostrarAlerta(context,
                                "Solo puedes acceder a actividades del día de hoy.");
                            return;
                          }

                          if (!esHoraPermitida) {
                            _mostrarAlerta(context,
                                "No puedes registrar la entrada fuera del rango de 30 minutos antes o después de la hora programada.");
                            return;
                          }

                          if (estado == "entrada") {
                            // Si ya registró entrada → Ir a `RegisterExitScreen`
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterExitScreen(
                                  id: activity['id'],
                                  title: activity['title'],
                                ),
                              ),
                            );
                          } else {
                            // Si no ha registrado entrada → Ir a `DiligenciaScreen`
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DiligenciaScreen(
                                  id: activity['id'],
                                  title: activity['title'],
                                  imageUrl: activity['imageUrl'],
                                  location: activity['location'],
                                  date: activity['date'],
                                  time: activity['time'],
                                  onEntradaRegistrada: () {
                                    Provider.of<ActivityProvider>(context,
                                            listen: false)
                                        .actualizarEstadoRegistro(
                                            activity['id'], "entrada");
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2),
    );
  }

  // 🔥 Función para mostrar alerta
  void _mostrarAlerta(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
