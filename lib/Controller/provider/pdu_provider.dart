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
  String processorType = "-";

  String kva = "-";
  String voltageType = "-";

  // New Sensor Config
  String tempMeasure = "C"; // C or F

  // --- DATA ---
  List<Map<String, dynamic>> phasesData = [];
  List<OutletData> outlets = [];
  List<Map<String, dynamic>> mcbStatus = [];
  Map<String, dynamic> sensorData = {};
// NEW: Cache to store status because 'meter' and 'SwitchingAck' come separately
  final Map<int, bool> _outletStatusCache = {};

  // ... connectToBroker ...


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
    // 1. ADD 'OutletSwitchingAck' to topics
    final topics = ['BaseConfig', 'aggmeter', 'sensor', 'mcbs', 'meter', 'SensorConfig', 'OutletSwitchingAck'];

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
            processorType = data['processorType'] ?? "-";

            voltageType = data['voltageType'] ?? "-";
          }
          break;

        case 'SensorConfig': // New Topic for Unit
          if (data is Map<String, dynamic>) {
            tempMeasure = data['tempMeasure'] ?? "C";
          }
          break;

      // In Controller/provider/pdu_provider.dart

        case 'aggmeter':
          if (data is List) {
            // Filter: Only keep items that actually have a "Phase" key
            // AND exclude summary keys if they exist in the same list
            phasesData = List<Map<String, dynamic>>.from(data).where((item) {
              return item.containsKey("Phase");
            }).toList();
          }
          break;

        case 'sensor':
          if (data is Map<String, dynamic>) sensorData = data;
          break;

        case 'mcbs':
          if (data is List) mcbStatus = List<Map<String, dynamic>>.from(data);
          break;

        case 'OutletSwitchingAck':
        // 2. PARSE SWITCHING STATUS
          if (data is Map<String, dynamic>) {
            bool hasUpdates = false;

            data.forEach((key, value) {
              // Keys look like "Outlet1", "Outlet2"
              if (key.startsWith("Outlet")) {
                int? id = int.tryParse(key.replaceAll("Outlet", ""));
                if (id != null) {
                  bool isOn = value.toString() == "1";
                  _outletStatusCache[id] = isOn; // Update cache
                  hasUpdates = true;
                }
              }
            });

            // 3. Update existing 'outlets' list immediately to reflect UI change
            if (hasUpdates && outlets.isNotEmpty) {
              outlets = outlets.map((o) {
                int? oId = int.tryParse(o.id.replaceAll("Outlet ", ""));
                if (oId != null && _outletStatusCache.containsKey(oId)) {
                  // Re-create object with new 'isOn' status (since fields are final)
                  return OutletData(
                    id: o.id,
                    isOn: _outletStatusCache[oId]!,
                    current: o.current,
                    voltage: o.voltage,
                    activePower: o.activePower,
                    energy: o.energy,
                    powerFactor: o.powerFactor,
                    frequency: o.frequency,
                    apparentPower: o.apparentPower,
                  );
                }
                return o;
              }).toList();
            }
          }
          break;

        case 'meter':
          if (data is List) {
            outlets = data.map<OutletData>((e) {
              // Get ID to look up status
              int oId = e['outlet'] is int ? e['outlet'] : int.tryParse(e['outlet'].toString()) ?? 0;

              return OutletData(
                id: "Outlet $oId",
                // 4. USE CACHED STATUS (Default to true if not found yet)
                isOn: _outletStatusCache[oId] ?? true,

                current: double.tryParse(e['current']?.toString() ?? "0") ?? 0.0,
                voltage: double.tryParse(e['voltage']?.toString() ?? "0") ?? 0.0,
                activePower: double.tryParse(e['kWatt']?.toString() ?? "0") ?? 0.0,
                energy: double.tryParse(e['kWattHr']?.toString() ?? "0") ?? 0.0,
                powerFactor: double.tryParse(e['powerFactor']?.toString() ?? "0") ?? 0.0,
                frequency: double.tryParse(e['freqInHz']?.toString() ?? "0") ?? 0.0,
                apparentPower: double.tryParse(e['VA']?.toString() ?? "0") ?? 0.0,
              );
            }).toList();
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