import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ActivityProvider with ChangeNotifier {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get activities => _activities;
  bool get isLoading => _isLoading;

  Future<void> fetchActivities() async {
    if (_activities.isNotEmpty) return; // Evita recargar datos si ya existen

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://magicloops.dev/api/loop/259cb1d4-0a19-40cb-9523-2a67706902d8/run?parametro=valor'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _activities = data.map((item) {
          return {
            'id': item['id'].toString(), // ✅ Guardamos el ID de la actividad
            'title': item['title'],
            'imageUrl': item['imageUrl'],
            'location': item['location'],
            'date': item['date'],
            'time': item['time'],
            'estado_registro': null, // ✅ Inicialmente no tiene entrada ni salida
          };
        }).toList();
      }
    } catch (error) {
      debugPrint("Error al obtener actividades: $error");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔥 Método para actualizar el estado de la actividad (entrada o salida)
  void actualizarEstadoRegistro(String id, String estado) {
    int index = _activities.indexWhere((activity) => activity['id'] == id);
    if (index != -1) {
      _activities[index]['estado_registro'] = estado;
      notifyListeners();
    }
  }

  // 🔥 Verificar si ya registró entrada o salida
  String obtenerEstadoRegistro(String id) {
    final actividad = _activities.firstWhere((activity) => activity['id'] == id, orElse: () => {});
    return actividad.isNotEmpty ? actividad['estado_registro'] ?? '' : '';
  }

  void eliminarActividad(String id) {
  _activities.removeWhere((activity) => activity['id'].toString() == id);
  notifyListeners();
}

}
