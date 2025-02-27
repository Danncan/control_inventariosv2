import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';

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
            if (provider.activities.isEmpty) {
              return const Center(child: CircularProgressIndicator()); // 🔥 Loader mientras carga
            }

            return ListView.builder(
              itemCount: provider.activities.length,
              itemBuilder: (context, index) {
                final activity = provider.activities[index];

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
                              child: const Icon(Icons.image_not_supported, size: 30),
                            );
                          },
                        ),
                      ),
                      title: Text(
                        activity['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 ${activity['location']}"),
                          Text("📅 ${activity['date']} - 🕒 ${activity['time']}"),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.teal),
                        onPressed: () {
                          // 🔥 Aquí puedes navegar a la pantalla de detalles de la actividad
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
}
