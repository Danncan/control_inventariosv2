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
            'title': item['title'],
            'imageUrl': item['imageUrl'],
            'location': item['location'],
            'date': item['date'],
            'time': item['time'],
          };
        }).toList();
      }
    } catch (error) {
      debugPrint("Error al obtener actividades: $error");
    }

    _isLoading = false;
    notifyListeners();
  }
}
