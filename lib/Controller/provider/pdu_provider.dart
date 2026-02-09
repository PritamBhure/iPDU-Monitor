import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart'; // Mobile

import '../../Model/outletModel.dart';
import '../../Model/pdu_model.dart';

class PduController extends ChangeNotifier {
  final PduDevice device;
  MqttClient? client;

  // --- STATE ---
  bool isConnected = false;
  bool isLoading = false;
  String connectionStatus = "Disconnected";

  // --- CONFIG ---
  String pduName = "-";
  String productCode = "-";
  String serialNo = "-";
  String location = "-";
  String type = "-";
  String outletsCount = "-";
  String rating = "-";
  String kva = "-";
  String voltageType = "-";

  // New Sensor Config
  String tempMeasure = "C"; // C or F

  // --- DATA ---
  List<Map<String, dynamic>> phasesData = [];
  List<OutletData> outlets = [];
  List<Map<String, dynamic>> mcbStatus = [];
  Map<String, dynamic> sensorData = {};

  PduController(this.device);

  Future<void> connectToBroker(String ip, String username, String password) async {
    isLoading = true;
    connectionStatus = "Connecting...";
    notifyListeners();

    String clientID = 'flutter_pdu_${DateTime.now().millisecondsSinceEpoch}';

    // FIX: Web vs Mobile Client
    if (kIsWeb) {
      connectionStatus = "Error: Web not supported in this mobile build.";
      isLoading = false;
      notifyListeners();
      return;
    } else {
      client = MqttServerClient(ip, clientID);
      client!.port = 1883;
    }

    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      await client!.connect(username, password);
    } catch (e) {
      connectionStatus = "Error: $e";
      isLoading = false;
      notifyListeners();
      return;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      connectionStatus = "Online";
      _subscribeToTopics();
    } else {
      connectionStatus = "Failed: ${client!.connectionStatus!.state}";
    }

    isLoading = false;
    notifyListeners();
  }

  void _subscribeToTopics() {
    // Add 'SensorConfig' to topics
    final topics = ['BaseConfig', 'aggmeter', 'sensor', 'mcbs', 'meter', 'SensorConfig'];
    for (var t in topics) client!.subscribe(t, MqttQos.atMostOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _parseMessage(c[0].topic, pt);
    });
  }

  void _parseMessage(String topic, String payload) {
    try {
      dynamic data = jsonDecode(payload);

      switch (topic) {
        case 'BaseConfig':
          if (data is Map<String, dynamic>) {
            pduName = data['pduName'] ?? "-";
            productCode = data['productCode'] ?? "-";
            serialNo = data['serialNumber'] ?? "-";
            location = data['location'] ?? "-";
            type = data['type'] ?? "-";
            outletsCount = data['outlets'] ?? "-";
            rating = data['ratingInAmp'] ?? "-";
            kva = data['kva'] ?? "-";
            voltageType = data['voltageType'] ?? "-";
          }
          break;

        case 'SensorConfig': // New Topic for Unit
          if (data is Map<String, dynamic>) {
            tempMeasure = data['tempMeasure'] ?? "C";
          }
          break;

        case 'aggmeter':
          if (data is List) phasesData = List<Map<String, dynamic>>.from(data);
          break;

        case 'sensor':
          if (data is Map<String, dynamic>) sensorData = data;
          break;

        case 'mcbs':
          if (data is List) mcbStatus = List<Map<String, dynamic>>.from(data);
          break;

        case 'meter':
          if (data is List) {
            outlets = data.map<OutletData>((e) => OutletData(
              id: "Outlet ${e['outlet']}",
              current: double.tryParse(e['current']?.toString() ?? "0") ?? 0.0,
              voltage: double.tryParse(e['voltage']?.toString() ?? "0") ?? 0.0,
              activePower: double.tryParse(e['kWatt']?.toString() ?? "0") ?? 0.0,
              energy: double.tryParse(e['kWattHr']?.toString() ?? "0") ?? 0.0,
              powerFactor: double.tryParse(e['powerFactor']?.toString() ?? "0") ?? 0.0,
              frequency: double.tryParse(e['freqInHz']?.toString() ?? "0") ?? 0.0,
              apparentPower: double.tryParse(e['VA']?.toString() ?? "0") ?? 0.0,
            )).toList();
          }
          break;
      }
      notifyListeners();
    } catch (e) {
      print("Parse Error: $e");
    }
  }

  void _onDisconnected() {
    isConnected = false;
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  // --- HELPER: Process Sensor Value ---
  String getSensorDisplay(String key) {
    var rawVal = sensorData[key];
    if (rawVal == null) return "-";

    // Handle Numeric Sensors (Temp/Humidity)
    if (rawVal is num) {
      double val = rawVal.toDouble();
      if (val == 255.00) return "Not Connected";
      if (val == 254.00) return "Error";
      if (val == 253.00) return "Disable";

      // Valid Value formatting
      if (key.toLowerCase().contains("temp")) {
        return "${val.toStringAsFixed(1)} °$tempMeasure";
      } else if (key.toLowerCase().contains("humid")) {
        return "${val.toStringAsFixed(1)} %";
      }
      return val.toString();
    }

    // Handle String Sensors (Door, Smoke, Water)
    return rawVal.toString();
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }
}