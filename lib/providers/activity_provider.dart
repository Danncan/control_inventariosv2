import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';

class ActivityProvider with ChangeNotifier {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingUpdates = [];

  List<Map<String, dynamic>> get activities => _activities;
  bool get isLoading => _isLoading;
  final String _baseUrl = "http://192.168.1.201:3000";


  ActivityProvider() {
    _loadCachedActivities();
    _loadPendingUpdates();
    _monitorConnectivity();
  }

  /// Carga del caché local
  Future<void> _loadCachedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString("cached_activities");
    if (cached != null) {
      _activities = List<Map<String, dynamic>>.from(json.decode(cached));
      notifyListeners();
    }
  }

  /// Guarda en caché
  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("cached_activities", json.encode(_activities));
  }

  /// Trae las actividades desde el servidor usando el `userId` y
  /// envía el token como cookie `access_token`.
  Future<void> fetchActivities() async {
    // 1️⃣ Verifica conectividad
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      debugPrint('Sin conexión: no se cargarán actividades');
      return;
    }

    _isLoading = true;
    notifyListeners();

    // 2️⃣ Obtiene credenciales
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString("userId");
    final String? token  = prefs.getString("token");
    if (userId == null || token == null) {
      debugPrint('Faltan userId o token');
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final uri = Uri.parse("$_baseUrl/activity/internal/$userId");
      final resp = await http.get(
        uri,
        headers: {
          'Cookie': 'access_token=$token',
        },
      );
      debugPrint("Respuesta: ${resp.statusCode} ${resp.body}");

      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        _activities = data.map<Map<String, dynamic>>((item) {
          // Parseo de fecha y hora
          DateTime parsedDate = DateTime.parse(item['Activity_Date']);
          String formattedDate = DateFormat('dd-MMM-yyyy').format(parsedDate);
          String time = item['Activity_Time']?.toString().substring(0,5) ?? '';

          return {
            'id'              : item['Activity_ID'].toString(),
            'title'           : item['Activity_Name'] ?? '',
            'imageUrl'        : (item['Documents'] != null && item['Documents'].isNotEmpty)
                                ? item['Documents']
                                : (['assets/entrega.png', 'assets/diligencia.png']..shuffle()).first,
            'location'        : item['Activity_Location'] ?? '',
            'date'            : formattedDate,
            'time'            : time,
            'estado_registro' : item['Activity_Status'] ?? '',
          };
        }).toList();

        await _saveToCache();
      } else {
        debugPrint("Error HTTP ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al obtener actividades: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Guarda una entrada/salida pendiente
  void addPendingUpdate(Map<String, dynamic> update) {
    _pendingUpdates.add(update);
    _savePendingUpdates();
  }

  Future<void> _savePendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("pending_updates", json.encode(_pendingUpdates));
  }

  Future<void> _loadPendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString("pending_updates");
    if (cached != null) {
      _pendingUpdates = List<Map<String, dynamic>>.from(json.decode(cached));
    }
  }

  /// Sincroniza las pendientes cuando hay conexión
  Future<void> syncPendingUpdates() async {
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) return;

    for (var upd in _pendingUpdates) {
      await _sendUpdateToServer(upd);
    }
    _pendingUpdates.clear();
    await _savePendingUpdates();
  }

  Future<void> _sendUpdateToServer(Map<String, dynamic> update) async {
    try {
      final resp = await http.post(
        Uri.parse("http://localhost:3000/activity/update"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(update),
      );
      if (resp.statusCode == 200) {
        debugPrint("Update sincronizado");
      }
    } catch (e) {
      debugPrint("Error sync: $e");
    }
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((conn) {
      if (conn != ConnectivityResult.none) {
        syncPendingUpdates();
      }
    });
  }

  /// ---- Funciones de estado interno ----

  void actualizarEstadoRegistro(String id, String estado) {
    final idx = _activities.indexWhere((a) => a['id'] == id);
    if (idx != -1) {
      _activities[idx]['estado_registro'] = estado;
      notifyListeners();
    }
  }

  String obtenerEstadoRegistro(String id) {
    final act = _activities.firstWhere(
      (a) => a['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    return act.isNotEmpty ? (act['estado_registro'] ?? '') : '';
  }

  void eliminarActividad(String id) {
    _activities.removeWhere((a) => a['id'] == id);
    notifyListeners();
  }

  Future<void> registerActivityRecord({
    required String activityId,
    required String recordType, // "entrada" o "salida"
    required Position position,
  }) async {
    final conn = await Connectivity().checkConnectivity();

    // Construye el cuerpo del POST
    final Map<String, dynamic> payload = {
      'Activity_ID': int.parse(activityId),
      'Activity_Record_Type': recordType,
      'Activity_Record_Recorded_Time': DateTime.now().toIso8601String(),
      'Activity_Record_Latitude': position.latitude,
      'Activity_Record_Longitude': position.longitude,
      'Activity_Record_On_Time': true,
      'Activity_Record_Observation': ''
    };

    // Si NO hay conexión, lo guardamos para sincronizar luego
    if (conn == ConnectivityResult.none) {
      addPendingUpdate(payload);
      actualizarEstadoRegistro(activityId, recordType);
      return;
    }

    // Si hay conexión, hacemos el POST
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final resp = await http.post(
        Uri.parse("$_baseUrl/activity-record"),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Cookie': 'access_token=$token',
        },
        body: json.encode(payload),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        debugPrint("✅ Activity record creado: ${resp.body}");
        // Actualiza localmente la UI
        actualizarEstadoRegistro(activityId, recordType);
      } else {
        debugPrint("⚠️ Error HTTP ${resp.statusCode}: ${resp.body}");
        addPendingUpdate(payload);
      }
    } catch (e) {
      debugPrint("❌ Error creando activity-record: $e");
      addPendingUpdate(payload);
    }
  }

}
