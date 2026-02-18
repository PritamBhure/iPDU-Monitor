import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';

// Import your models and services here
import '../../Core/services/MQTT Services/MqttConectionServices.dart';
import '../../Core/services/updateOutletInfo.dart';
import '../../Core/services/updatePDUInfo.dart';
import '../../Core/services/updateSensorData.dart';
import '../../Core/services/updateThreePhaseCurrentThreshold.dart';
import '../../Model/outletModel.dart';
import '../../Model/pdu_model.dart';

class PduController extends ChangeNotifier {
  final PduDevice device;

  // --- SERVICES ---
  final MqttService _mqttService = MqttService();
  final iPDUInfoAPI _pduApiService = iPDUInfoAPI();
  final SensorThresholdAPI _sensorApiService = SensorThresholdAPI();
  final ElectricalThresholdAPI _elecThresholdService = ElectricalThresholdAPI();
  final OutletAPI _outletApiService = OutletAPI();

  // --- STATE ---
  bool isConnected = false;
  bool isLoading = false;
  String connectionStatus = "Disconnected";

  // --- CONFIG VARIABLES ---
  String pduName = "-";
  String productCode = "-";
  String serialNo = "-";
  String location = "-";
  String type = "-";
  String outletsCount = "-";
  String rating = "-";
  String processorType = "-";
  String kva = "-";
  String voltageType = "-";
  String email = "-";

  // --- SENSOR STATE ---
  String tempMeasure = "C";
  Map<String, dynamic> sensorConfigData = {};
  Map<String, dynamic> sensorData = {};

  // --- OUTLET & ELECTRICAL STATE ---
  List<Map<String, dynamic>> phasesData = [];
  List<OutletData> outlets = [];
  List<Map<String, dynamic>> mcbStatus = [];

  // Stores "1": "Server Name"
  Map<String, String> outletNamesConfig = {};
  // Stores "1": { "status": "Enable", "overLoad": "10.0"... }
  Map<String, Map<String, dynamic>> outletThresholdConfig = {};

  // Internal cache for outlet on/off status
  final Map<int, bool> _outletStatusCache = {};

  // --- NEW: ELECTRICAL THRESHOLD STATE ---
  // Stores the data from "PhaseThreshold" topic
  Map<String, String> electricalThresholds = {};


  PduController(this.device);

  // =========================================================
  //  MQTT CONNECTION LOGIC
  // =========================================================

  Future<void> connectToBroker(String ip, String username, String password) async {
    isLoading = true;
    notifyListeners();

    // 1. Listen to connection status changes
    _mqttService.statusStream.listen((status) {
      connectionStatus = status;
      isConnected = (status == "Online");
      notifyListeners();
    });

    // 2. Listen to incoming data messages
    _mqttService.messageStream.listen((payload) {
      _processMqttMessage(payload.topic, payload.data);
    });

    // 3. Initiate Connection
    bool success = await _mqttService.connect(
        ip: ip,
        username: username,
        password: password
    );

    if (success) {
      _subscribeToTopics();
    }

    isLoading = false;
    notifyListeners();
  }

  void _subscribeToTopics() {
    final topics = [
      'BaseConfig',
      'aggmeter',
      'sensor',
      'mcbs',
      'meter',
      'SensorConfig',
      'OutletSwitchingAck',
      'OutletNames',
      'outletThreshold',
      'PhaseThreshold', // <--- 1. ADD THIS TOPIC
    ];
    _mqttService.subscribeToTopics(topics);
  }

  /// Central method to route messages to specific handlers
  void _processMqttMessage(String topic, dynamic data) {
    try {
      switch (topic) {
        case 'BaseConfig':
          _handleBaseConfig(data);
          break;
        case 'SensorConfig':
          _handleSensorConfig(data);
          break;
        case 'sensor':
          if (data is Map<String, dynamic>) sensorData = data;
          break;
        case 'aggmeter':
          _handleAggMeter(data);
          break;
        case 'mcbs':
          if (data is List) mcbStatus = List<Map<String, dynamic>>.from(data);
          break;
        case 'OutletSwitchingAck':
          _handleOutletSwitchingAck(data);
          break;
        case 'OutletNames':
          _handleOutletNames(data);
          break;
        case 'outletThreshold':
          _handleOutletThresholds(data);
          break;
        case 'meter':
          _handleMeterData(data);
          break;
        case 'PhaseThreshold': // <--- 2. HANDLE THIS TOPIC
          _handlePhaseThresholds(data);
          break;


      }
      notifyListeners();
    } catch (e) {
      log("Data Handling Error ($topic): $e");
    }
  }

  // =========================================================
  //  DATA HANDLERS (Private Helpers to keep code clean)
  // =========================================================



  // --- 3. DATA HANDLER ---
  void _handlePhaseThresholds(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Store as String Map for easy text field population
      electricalThresholds = data.map((key, value) => MapEntry(key, value.toString()));
    }
  }

  void _handleBaseConfig(Map<String, dynamic> data) {
    pduName = data['pduName']?.toString() ?? "-";
    productCode = data['productCode']?.toString() ?? "-";
    serialNo = data['serialNumber']?.toString() ?? "-";
    location = data['location']?.toString() ?? "-";
    type = data['type']?.toString() ?? "-";
    outletsCount = data['outlets']?.toString() ?? "-";
    rating = data['ratingInAmp']?.toString() ?? "-";
    email = data['contact']?.toString() ?? "";
    processorType = data['processorType']?.toString() ?? "-";
    voltageType = data['voltageType']?.toString() ?? "-";

    // Handle KVA parsing safely
    var rawKva = data['kva'];
    double? kvaValue = double.tryParse(rawKva?.toString() ?? "");
    kva = (kvaValue != null) ? kvaValue.toStringAsFixed(2) : (rawKva?.toString() ?? "-");
  }

  void _handleSensorConfig(Map<String, dynamic> data) {
    sensorConfigData = data;
    tempMeasure = data['tempMeasure'] ?? "C";
  }

  void _handleAggMeter(dynamic data) {
    if (data is List) {
      phasesData = List<Map<String, dynamic>>.from(data)
          .where((item) => item.containsKey("Phase"))
          .toList();
    }
  }

  void _handleOutletNames(Map<String, dynamic> data) {
    outletNamesConfig = data.map((key, value) => MapEntry(key, value.toString()));
  }

  void _handleOutletThresholds(List<dynamic> data) {
    for (var item in data) {
      if (item is Map<String, dynamic> && item.containsKey('outlet')) {
        String id = item['outlet'].toString();
        outletThresholdConfig[id] = item;
      }
    }
  }

  void _handleOutletSwitchingAck(Map<String, dynamic> data) {
    bool hasUpdates = false;

    // 1. Update the internal cache
    data.forEach((key, value) {
      if (key.startsWith("Outlet")) {
        int? id = int.tryParse(key.replaceAll("Outlet", ""));
        if (id != null) {
          // Convert "1"/"0" to boolean
          _outletStatusCache[id] = (value.toString() == "1");
          hasUpdates = true;
        }
      }
    });

    // 2. Refresh the main outlets list if cache changed
    if (hasUpdates && outlets.isNotEmpty) {
      outlets = outlets.map((o) {
        // Extract ID (e.g., "Outlet 1" -> 1)
        int? oId = int.tryParse(o.id.replaceAll("Outlet ", ""));

        // If we have an updated status for this outlet, create a new object
        if (oId != null && _outletStatusCache.containsKey(oId)) {
          return OutletData(
            id: o.id,
            isOn: _outletStatusCache[oId]!, // <--- The only field that changes
            current: o.current,
            voltage: o.voltage,
            activePower: o.activePower,
            energy: o.energy,
            powerFactor: o.powerFactor,
            frequency: o.frequency,
            apparentPower: o.apparentPower,
          );
        }
        // Otherwise, return the original object unchanged
        return o;
      }).toList();

      notifyListeners(); // Notify UI to rebuild
    }



  }
  void _handleMeterData(List<dynamic> data) {
    outlets = data.map<OutletData>((e) {
      int oId = e['outlet'] is int ? e['outlet'] : int.tryParse(e['outlet'].toString()) ?? 0;

      // Helper to safely parse doubles
      double parseDbl(dynamic v) => double.tryParse(v?.toString() ?? "0") ?? 0.0;

      return OutletData(
        id: "Outlet $oId",
        isOn: _outletStatusCache[oId] ?? true, // Use cached status or default true
        current: parseDbl(e['current']),
        voltage: parseDbl(e['voltage']),
        activePower: parseDbl(e['kWatt']),
        energy: parseDbl(e['kWattHr']),
        powerFactor: parseDbl(e['powerFactor']),
        frequency: parseDbl(e['freqInHz']),
        apparentPower: parseDbl(e['VA']),
      );
    }).toList();
  }



  // =========================================================
  //  API ACTION METHODS
  // =========================================================

  Future<bool> updatePduConfig({
    required String newName,
    required String newLocation,
    required String newContact,
    required String username,
    required String password,
  }) async {
    isLoading = true;
    notifyListeners();

    bool success = await _pduApiService.updatePduConfig(
      ip: device.ip,
      pduName: newName,
      location: newLocation,
      contact: newContact,
      username: username,
      password: password,
    );

    if (success) {
      pduName = newName;
      location = newLocation;
      email = newContact;
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateElectricalThresholds({
    required String username,
    required String password,
    required Map<String, String> data,
  }) async {
    return _performApiCall(() => _elecThresholdService.updateThresholds(
      ip: device.ip,
      username: username,
      password: password,
      thresholds: data,
    ));
  }

  Future<bool> updateSensorConfiguration({
    required String username,
    required String password,
    required Map<String, String> data,
  }) async {
    return _performApiCall(() => _sensorApiService.updateSensorConfig(
      ip: device.ip,
      username: username,
      password: password,
      configData: data,
    ));
  }

  Future<bool> updateOutletNames({
    required String username,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    return _performApiCall(() => _outletApiService.updateOutletNames(
      ip: device.ip,
      username: username,
      password: password,
      data: data,
    ));
  }

  Future<bool> updateOutletThresholds({
    required String username,
    required String password,
    required List<Map<String, dynamic>> data,
  }) async {
    return _performApiCall(() => _outletApiService.updateThresholds(
      ip: device.ip,
      username: username,
      password: password,
      payload: data,
    ));
  }

  /// Helper to reduce boilerplate for API calls
  Future<bool> _performApiCall(Future<bool> Function() apiCall) async {
    isLoading = true;
    notifyListeners();
    bool success = await apiCall();
    isLoading = false;
    notifyListeners();
    return success;
  }

  // =========================================================
  //  DISPLAY HELPERS
  // =========================================================

  String getSensorDisplay(String key) {
    // 1. Check if the sensor is explicitly disabled in config
    String statusKey = "";
    final RegExp regExp = RegExp(r'^(th\d+)');
    final match = regExp.firstMatch(key);

    if (match != null) {
      statusKey = "${match.group(1)}status"; // e.g., th01status
    }

    if (statusKey.isNotEmpty && sensorConfigData.containsKey(statusKey)) {
      if (sensorConfigData[statusKey].toString() == "0") return "Disable";
    }

    // 2. Process Raw Value
    var rawVal = sensorData[key];
    if (rawVal == null) return "-";

    // 3. Handle Numeric Sensors
    if (rawVal is num) {
      double val = rawVal.toDouble();
      if (val == 255.00) return "Not Connected";
      if (val == 254.00) return "Error";
      if (val == 253.00) return "Disable";

      if (key.toLowerCase().contains("temp")) return "${val.toStringAsFixed(1)} °$tempMeasure";
      if (key.toLowerCase().contains("humid")) return "${val.toStringAsFixed(1)} %";

      return val.toString();
    }

    // 4. Handle String Sensors
    return rawVal.toString();
  }

  @override
  void dispose() {
    _mqttService.dispose();
    super.dispose();
  }
}