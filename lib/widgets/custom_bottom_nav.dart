import 'package:flutter/material.dart';
import '../views/home_screen.dart';
import '../views/calendar_screen.dart';
import '../views/activity_list_screen.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Evita recargar la misma pantalla

    Widget screen;
    switch (index) {
      case 0:
        screen = const CalendarScreen();
        break;
      case 1:
        screen = const HomeScreen();
        break;
      case 2:
        screen = const ActivityListScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: "Calendario"),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "Listado"),
      ],
    );
  }
}
