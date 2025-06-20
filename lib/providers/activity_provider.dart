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
  bool _isOffline = false;                     // ✅ Nuevo flag
  List<Map<String, dynamic>> _pendingUpdates = [];

  List<Map<String, dynamic>> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;            // ✅ Getter
  final String _baseUrl = "http://192.168.18.104:3000";

  ActivityProvider() {
    _monitorConnectivity();
    _loadOfflineFlag();                         // ✅ Carga modo offline
    _loadCachedActivities();
    _loadPendingUpdates();
  }

  // 🔹 Nuevo: lee el flag offline de SharedPreferences
  Future<void> _loadOfflineFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _isOffline = prefs.getBool("is_offline") ?? false;
    notifyListeners();
  }

  // 🔹 Nuevo: guarda el flag offline en SharedPreferences
  Future<void> _saveOfflineFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_offline", _isOffline);
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

  /// Toggle modo offline
  Future<void> toggleOfflineMode() async {
    _isOffline = !_isOffline;
    await _saveOfflineFlag();

    if (_isOffline) {
      // Al activar offline: trae del servidor y cachea
      await fetchActivities();
    } else {
      // Al desactivar: sincroniza pendientes
      await syncPendingUpdates();
    }
    notifyListeners();
  }

  /// Trae las actividades desde el servidor usando el `userId` y
  /// envía el token como cookie `access_token`.
  Future<void> fetchActivities() async {
  // 🔹 Si estamos en modo offline, cargamos sólo del cache y no tocamos la red
  if (_isOffline) {
    debugPrint('Modo offline activo: cargando de cache');
    return;
  }

  // 🔹 Si no hay conexión y NO estamos en modo offline, abortamos
  final conn = await Connectivity().checkConnectivity();
  if (conn == ConnectivityResult.none) {
    debugPrint('Sin conexión: no se cargarán actividades');
    return;
  }

  _isLoading = true;
  notifyListeners();

  // 2️⃣ Credenciales
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
      headers: {'Cookie': 'access_token=$token'},
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = json.decode(resp.body);
      _activities = data.map<Map<String, dynamic>>((item) {
        DateTime parsedDate = DateTime.parse(item['Activity_Date']);
        String formattedDate = DateFormat('dd-MMM-yyyy').format(parsedDate);
        String time = item['Activity_StartTime']?.toString().substring(0,5) ?? '';
        return {
          'id'              : item['Activity_ID'].toString(),
          'title'           : item['Activity_Type'] ?? '',
          'imageUrl'        : (['assets/entrega.png', 'assets/diligencia.png']..shuffle()).first,
          'location'        : item['Activity_Location'] ?? '',
          'date'            : formattedDate,
          'time'            : time,
          'estado_registro' : item['Activity_Status'] ?? '',
        };
      }).toList();

      await _saveToCache();  // 🔹 Actualiza el cache con la nueva lista
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
        Uri.parse("$_baseUrl/activity/update"),
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
      if (conn != ConnectivityResult.none && !_isOffline) {
        // Si volvemos online y NO estamos en modo offline,
        // sincronizamos las pendientes
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

    final payload = {
      'Activity_ID'                  : int.parse(activityId),
      'Activity_Record_Type'         : recordType,
      'Activity_Record_Recorded_Time': DateTime.now().toIso8601String(),
      'Activity_Record_Latitude'     : position.latitude,
      'Activity_Record_Longitude'    : position.longitude,
      'Activity_Record_On_Time'      : true,
      'Activity_Record_Observation'  : ''
    };

    if (conn == ConnectivityResult.none || _isOffline) {
      // 🔹 Ahora también chequea _isOffline
      addPendingUpdate(payload);
      actualizarEstadoRegistro(activityId, recordType);
      return;
    }

    // Online normal
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
