import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/activity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageControllerHoy = PageController();
  final PageController _pageControllerProximas = PageController();

  final List<Map<String, String>> actividadesHoy = [
    {
      'title': 'Juicio de Alimentos',
      'imageUrl': 'assets/diligencia.png',
      'location': 'Plataforma Gubernamental Norte',
      'date': '23-Oct-2025',
      'time': '13:45',
    },
    {
      'title': 'Entrega de Documentos',
      'imageUrl': 'assets/entrega.png',
      'location': 'Corte Suprema',
      'date': '23-Oct-2025',
      'time': '14:00',
    },
    {
      'title': 'Juicio de Alimentos',
      'imageUrl': 'assets/diligencia.png',
      'location': 'Plataforma Gubernamental Norte',
      'date': '23-Oct-2025',
      'time': '13:45',
    },
    {
      'title': 'Entrega de Documentos',
      'imageUrl': 'assets/entrega.png',
      'location': 'Corte Suprema',
      'date': '23-Oct-2025',
      'time': '14:00',
    },
  ];

  final List<Map<String, String>> actividadesProximas = [
    {
      'title': 'Juicio de Alimentos',
      'imageUrl': 'assets/diligencia.png',
      'location': 'Plataforma Gubernamental Norte',
      'date': '25-Oct-2025',
      'time': '09:30',
    },
    {
      'title': 'Entrega de Documentos',
      'imageUrl': 'assets/entrega.png',
      'location': 'Corte Suprema',
      'date': '25-Oct-2025',
      'time': '10:15',
    },
    {
      'title': 'Juicio de Alimentos',
      'imageUrl': 'assets/diligencia.png',
      'location': 'Plataforma Gubernamental Norte',
      'date': '25-Oct-2025',
      'time': '09:30',
    },
    {
      'title': 'Entrega de Documentos',
      'imageUrl': 'assets/entrega.png',
      'location': 'Corte Suprema',
      'date': '25-Oct-2025',
      'time': '10:15',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Actividades Por Realizar'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Actividades de Hoy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Carrusel con PageView y SmoothPageIndicator
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
