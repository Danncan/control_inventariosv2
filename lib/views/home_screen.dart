import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart'; 
import '../widgets/custom_appbar.dart';
import '../widgets/activity_card.dart';
import '../providers/activity_provider.dart';
import '../widgets/custom_bottom_nav.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState(); // Eliminamos `_`
}

class HomeScreenState extends State<HomeScreen> {
  final PageController _pageControllerHoy = PageController();
  final PageController _pageControllerProximas = PageController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ActivityProvider>();
    Future.microtask(() async {
      await provider.fetchActivities();
      if (!mounted) return; // 🔥 Verifica si el widget sigue montado antes de usar context
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = context.watch<ActivityProvider>();
    final today = DateFormat('dd-MMM-yyyy').format(DateTime.now()); // Obtiene la fecha actual
    debugPrint(today);    // 🔥 Separar actividades en "Hoy" y "Próximas"
    final actividadesHoy = activityProvider.activities
        .where((actividad) => actividad['date'] == today)
        .toList();

    final actividadesProximas = activityProvider.activities
        .where((actividad) => actividad['date'] != today)
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Actividades Por Realizar'),
      body: activityProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activityProvider.activities.isEmpty
              ? const Center(child: Text("No hay actividades disponibles"))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Actividades de Hoy",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Carrusel de actividades de hoy
                      SizedBox(
                        height: 280,
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageControllerHoy,
                                itemCount: actividadesHoy.length,
                                itemBuilder: (context, index) {
                                  final actividad = actividadesHoy[index];
                                  return ActivityCard(
                                    id: actividad['id']!,
                                    title: actividad['title']!,
                                    imageUrl: actividad['imageUrl']!,
                                    location: actividad['location']!,
                                    date: actividad['date']!,
                                    time: actividad['time']!,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Indicador de páginas
                            Center(
                              child: SmoothPageIndicator(
                                controller: _pageControllerHoy,
                                count: actividadesHoy.length,
                                effect: const ExpandingDotsEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: Colors.teal,
                                  dotColor: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Actividades Próximas",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              // Acción para ver todas las actividades
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Carrusel de actividades próximas
                      SizedBox(
                        height: 280,
                        child: Column(
                          children: [
                            Expanded(
                              child: PageView.builder(
                                controller: _pageControllerProximas,
                                itemCount: actividadesProximas.length,
                                itemBuilder: (context, index) {
                                  final actividad = actividadesProximas[index];
                                  return ActivityCard(
                                   id: actividad['id']!,
                                    title: actividad['title']!,
                                    imageUrl: actividad['imageUrl']!,
                                    location: actividad['location']!,
                                    date: actividad['date']!,
                                    time: actividad['time']!,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Indicador de páginas
                            Center(
                              child: SmoothPageIndicator(
                                controller: _pageControllerProximas,
                                count: actividadesProximas.length,
                                effect: const ExpandingDotsEffect(
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  activeDotColor: Colors.teal,
                                  dotColor: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}