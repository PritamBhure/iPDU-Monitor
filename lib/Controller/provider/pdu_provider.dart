import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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

  // --- SENSOR CONFIG ---
  String tempMeasure = "C";
  Map<String, dynamic> sensorConfigData = {}; // Store full config here

  // --- DATA ---
  List<Map<String, dynamic>> phasesData = [];
  List<OutletData> outlets = [];
  List<Map<String, dynamic>> mcbStatus = [];
  Map<String, dynamic> sensorData = {};

  final Map<int, bool> _outletStatusCache = {};

  PduController(this.device);

  Future<void> connectToBroker(String ip, String username, String password) async {
    isLoading = true;
    connectionStatus = "Connecting...";
    notifyListeners();

    String clientID = 'flutter_pdu_${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // WEB: Uses WebSockets (ws://)
      // Ensure port is 9001 (or 8083) depending on your broker settings
      // Note: If your site is HTTPS, this MUST be wss://
      client = MqttBrowserClient('ws://$ip', clientID);
      client!.port = 9001;
    } else {
      // MOBILE: Uses TCP
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
            pduName = data['pduName']?.toString() ?? "-";
            productCode = data['productCode']?.toString() ?? "-";
            serialNo = data['serialNumber']?.toString() ?? "-";
            location = data['location']?.toString() ?? "-";
            type = data['type']?.toString() ?? "-";
            outletsCount = data['outlets']?.toString() ?? "-";
            rating = data['ratingInAmp']?.toString() ?? "-";

            var rawKva = data['kva'];
            double? kvaValue = double.tryParse(rawKva?.toString() ?? "");
            if (kvaValue != null) {
              kva = kvaValue.toStringAsFixed(2);
            } else {
              kva = rawKva?.toString() ?? "-";
            }

            processorType = data['processorType']?.toString() ?? "-";
            voltageType = data['voltageType']?.toString() ?? "-";
          }
          break;

        case 'SensorConfig':
          if (data is Map<String, dynamic>) {
            sensorConfigData = data; // 1. Save Full Config Map
            tempMeasure = data['tempMeasure'] ?? "C";
          }
          break;

        case 'aggmeter':
          if (data is List) {
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
          if (data is Map<String, dynamic>) {
            bool hasUpdates = false;
            data.forEach((key, value) {
              if (key.startsWith("Outlet")) {
                int? id = int.tryParse(key.replaceAll("Outlet", ""));
                if (id != null) {
                  bool isOn = value.toString() == "1";
                  _outletStatusCache[id] = isOn;
                  hasUpdates = true;
                }
              }
            });

            if (hasUpdates && outlets.isNotEmpty) {
              outlets = outlets.map((o) {
                int? oId = int.tryParse(o.id.replaceAll("Outlet ", ""));
                if (oId != null && _outletStatusCache.containsKey(oId)) {
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
              int oId = e['outlet'] is int ? e['outlet'] : int.tryParse(e['outlet'].toString()) ?? 0;
              return OutletData(
                id: "Outlet $oId",
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
      log("Parse Error: $e");
    }
  }

  void _onDisconnected() {
    isConnected = false;
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  String getSensorDisplay(String key) {
    // 2. CHECK CONFIG STATUS FIRST
    // Logic: If key is "th01temperature", look for "th01status"
    String statusKey = "";
    final RegExp regExp = RegExp(r'^(th\d+)'); // Matches th01, th02 etc.
    final match = regExp.firstMatch(key);

    if (match != null) {
      statusKey = "${match.group(1)}status"; // e.g. th01status
    }
    // (Optional) Map other keys if needed:
    // else if (key.contains("door")) statusKey = "doorStatus";

    // If status exists and is "0", return Disable immediately
    if (statusKey.isNotEmpty && sensorConfigData.containsKey(statusKey)) {
      if (sensorConfigData[statusKey].toString() == "0") {
        return "Disable";
      }
    }

    // 3. Normal Value Processing
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