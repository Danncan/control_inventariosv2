import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/activity_card.dart';
import '../widgets/custom_bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Map<String, String>>> _events = {};
  bool _isLoading = true; // 🔥 Para manejar la carga de datos

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() async {
    final provider = context.read<ActivityProvider>();
    if (provider.activities.isEmpty) {
      await provider.fetchActivities(); // 🔥 Solo carga si no hay datos en memoria
    }
    _mapActivitiesToCalendar(provider.activities);
  }

 void _mapActivitiesToCalendar(List<Map<String, dynamic>> activities) {
    Map<DateTime, List<Map<String, String>>> mappedEvents = {};

    for (var activity in activities) {
      // 🔥 Convertir la fecha correctamente
      DateTime activityDate = DateFormat("dd-MMM-yyyy").parse(activity['date']!);

      // 🔥 Normalizar la fecha (establecerla a medianoche en UTC)
      DateTime normalizedDate = DateTime.utc(activityDate.year, activityDate.month, activityDate.day);

      print("Original: $activityDate -> Normalized: $normalizedDate"); // 🔍 Debugging

      // Agregar la actividad al mapa de eventos
      mappedEvents.putIfAbsent(normalizedDate, () => []).add(
        activity.map((key, value) => MapEntry(key, value.toString())),
      );
    }

    setState(() {
      _events = mappedEvents;
      _isLoading = false;
    });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Calendario', showBackButton: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 🔥 Muestra un loader mientras carga
          : Column(
              children: [
                // 📅 **Calendario de Actividades**
                TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) => _events[day] ?? [],
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    markersAlignment: Alignment.bottomCenter, // 🔥 Alinea los marcadores
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                const SizedBox(height: 10),

                // 📋 **Lista de Actividades del Día Seleccionado**
                Expanded(
                  child: _selectedDay == null || _events[_selectedDay] == null
                      ? const Center(
                          child: Text(
                            "Selecciona un día para ver actividades.",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _events[_selectedDay]!.length,
                          itemBuilder: (context, index) {
                            final activity = _events[_selectedDay]![index];
                            return ActivityCard(
                              title: activity['title']!,
                              imageUrl: activity['imageUrl']!,
                              location: activity['location']!,
                              date: activity['date']!,
                              time: activity['time']!,
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}