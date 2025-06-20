import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/activity_card.dart';
import '../providers/activity_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PageController _pageControllerHoy = PageController();
  final PageController _pageControllerProximas = PageController();

  bool _hasConnection = true;
  late StreamSubscription<ConnectivityResult> _connectivitySub;

  @override
  void initState() {
    super.initState();

    // 1️⃣ Sigue escuchando cambios de conectividad…
    Connectivity().checkConnectivity().then((res) {
      setState(() => _hasConnection = res != ConnectivityResult.none);
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((res) {
      final connected = res != ConnectivityResult.none;
      if (connected != _hasConnection) {
        setState(() => _hasConnection = connected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connected ? 'Conexión restablecida' : 'Sin conexión',
            ),
            backgroundColor: connected ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // 2️⃣ Solo tras el primer frame, chequeamos el flag offline y hacemos fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      if (!provider.isOffline) {
        provider.fetchActivities();
      } else {
        debugPrint('Modo offline activo: cargando actividades de cache');
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _pageControllerHoy.dispose();
    _pageControllerProximas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activityProvider = context.watch<ActivityProvider>();

    // Fecha de hoy
    final today = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    // Filtra listas
    final actividadesHoy = activityProvider.activities
        .where((a) => a['date'] == today)
        .toList();
    final actividadesProximas = activityProvider.activities
        .where((a) => a['date'] != today)
        .toList();

    Widget body;
    if (activityProvider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (activityProvider.activities.isEmpty) {
      body = const Center(child: Text("No hay actividades disponibles"));
    } else {
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Actividades de Hoy",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageControllerHoy,
                      itemCount: actividadesHoy.length,
                      itemBuilder: (ctx, i) {
                        final a = actividadesHoy[i];
                        return ActivityCard(
                          id: a['id'],
                          title: a['title'],
                          imageUrl: a['imageUrl'],
                          location: a['location'],
                          date: a['date'],
                          time: a['time'],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
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
                const Text("Actividades Próximas",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    // Navegar a todas las próximas...
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageControllerProximas,
                      itemCount: actividadesProximas.length,
                      itemBuilder: (ctx, i) {
                        final a = actividadesProximas[i];
                        return ActivityCard(
                          id: a['id'],
                          title: a['title'],
                          imageUrl: a['imageUrl'],
                          location: a['location'],
                          date: a['date'],
                          time: a['time'],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
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
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Actividades Por Realizar'),
      body: Column(
        children: [
          if (!_hasConnection)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: Text(
                  "Sin conexión: mostrando datos locales",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}
