import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ActivityProvider with ChangeNotifier {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = false;
  bool _isOfflineMode = false; // 🔥 Estado del modo offline
  List<Map<String, dynamic>> _pendingUpdates = []; // 🔥 Peticiones pendientes

  List<Map<String, dynamic>> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;

  ActivityProvider() {
    _loadCachedActivities();
    _loadPendingUpdates();
    _monitorConnectivity();
  }

  // 🔥 Alternar modo offline
  void toggleOfflineMode(bool isOffline) {
    _isOfflineMode = isOffline;
    notifyListeners();
  }

  // 🔥 Cargar actividades desde caché
  Future<void> _loadCachedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString("cached_activities");

    if (cachedData != null) {
      _activities = List<Map<String, dynamic>>.from(json.decode(cachedData));
      notifyListeners();
    }
  }

  // 🔥 Guardar actividades en caché
  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("cached_activities", json.encode(_activities));
  }

  // 🔥 Obtener actividades (online u offline)
  Future<void> fetchActivities() async {
    if (_isOfflineMode) return; // 🔥 No recargar si está en modo offline

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return; // Si no hay conexión, usa los datos en caché
    }

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
            'id': item['id'].toString(),
            'title': item['title'],
            'imageUrl': item['imageUrl'],
            'location': item['location'],
            'date': item['date'],
            'time': item['time'],
            'estado_registro': null,
          };
        }).toList();

        await _saveToCache(); // Guarda en caché
      }
    } catch (error) {
      debugPrint("Error al obtener actividades: $error");
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔥 Guardar una entrada/salida pendiente
  void addPendingUpdate(Map<String, dynamic> update) {
    _pendingUpdates.add(update);
    _savePendingUpdates();
  }

  // 🔥 Guardar las actualizaciones pendientes en caché
  Future<void> _savePendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("pending_updates", json.encode(_pendingUpdates));
  }

  // 🔥 Cargar tareas pendientes del caché
  Future<void> _loadPendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedUpdates = prefs.getString("pending_updates");

    if (cachedUpdates != null) {
      _pendingUpdates = List<Map<String, dynamic>>.from(json.decode(cachedUpdates));
    }
  }

  // 🔥 Sincronizar tareas pendientes cuando vuelva el internet
  Future<void> syncPendingUpdates() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    for (var update in _pendingUpdates) {
      await _sendUpdateToServer(update);
    }

    _pendingUpdates.clear();
    await _savePendingUpdates();
  }

  // 🔥 Enviar datos al servidor
  Future<void> _sendUpdateToServer(Map<String, dynamic> update) async {
    try {
      final response = await http.post(
        Uri.parse('https://tu-api.com/actualizar'),
        body: json.encode(update),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        debugPrint("Actualización sincronizada con éxito.");
      }
    } catch (e) {
      debugPrint("Error al sincronizar datos: $e");
    }
  }

  // 🔥 Monitorear cambios en la conectividad
  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((connectivityResult) {
      if (connectivityResult != ConnectivityResult.none) {
        syncPendingUpdates();
      }
    });
  }

  // 🔥 Actualizar el estado de la actividad (entrada o salida)
  void actualizarEstadoRegistro(String id, String estado) {
    int index = _activities.indexWhere((activity) => activity['id'] == id);
    if (index != -1) {
      _activities[index]['estado_registro'] = estado;

      if (_isOfflineMode) {
        addPendingUpdate({
          'id': id,
          'estado_registro': estado,
        });
      }

      notifyListeners();
    }
  }

  // 🔥 Verificar si ya registró entrada o salida
  String obtenerEstadoRegistro(String id) {
    final actividad = _activities.firstWhere((activity) => activity['id'] == id, orElse: () => {});
    return actividad.isNotEmpty ? actividad['estado_registro'] ?? '' : '';
  }

  // 🔥 Eliminar actividad (cuando se registra la salida)
  void eliminarActividad(String id) {
    _activities.removeWhere((activity) => activity['id'].toString() == id);
    notifyListeners();
  }
}
