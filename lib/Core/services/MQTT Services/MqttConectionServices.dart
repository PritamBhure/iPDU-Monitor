import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// A simple model to pass MQTT messages back to the controller
class MqttPayload {
  final String topic;
  final dynamic data; // Decoded JSON data
  MqttPayload({required this.topic, required this.data});
}

class MqttService {
  MqttClient? _client;

  // Streams to notify the controller about updates
  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<MqttPayload> _messageController = StreamController<MqttPayload>.broadcast();

  // Getters for the streams
  Stream<String> get statusStream => _statusController.stream;
  Stream<MqttPayload> get messageStream => _messageController.stream;

  /// Connects to the MQTT Broker
  Future<bool> connect({
    required String ip,
    required String username,
    required String password,
  }) async {
    _updateStatus("Connecting...");

    String clientID = 'flutter_pdu_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Initialize Client based on Platform
    if (kIsWeb) {
      // Web uses WebSockets (usually port 9001 or 8083)
      _client = MqttBrowserClient('ws://$ip', clientID);
      _client!.port = 9001;
    } else {
      // Mobile uses TCP (usually port 1883)
      _client = MqttServerClient(ip, clientID);
      _client!.port = 1883;
    }

    // 2. Client Configuration
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientID)
        .startClean() // Start with a clean session
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMess;

    // 3. Attempt Connection
    try {
      await _client!.connect(username, password);
    } catch (e) {
      _updateStatus("Error: $e");
      _client!.disconnect();
      return false;
    }

    // 4. Verify Connection
    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _updateStatus("Online");
      _listenToUpdates();
      return true;
    } else {
      _updateStatus("Failed: ${_client!.connectionStatus!.state}");
      _client!.disconnect();
      return false;
    }
  }

  /// Subscribes to a list of topics
  void subscribeToTopics(List<String> topics) {
    if (_client == null || _client!.connectionStatus!.state != MqttConnectionState.connected) return;

    for (var topic in topics) {
      _client!.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  /// Listens to the incoming stream and decodes JSON
  void _listenToUpdates() {
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final String rawString = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        // Decode JSON here to save work in the controller
        final dynamic decodedData = jsonDecode(rawString);

        // Add to stream
        _messageController.add(MqttPayload(
            topic: c[0].topic,
            data: decodedData
        ));
      } catch (e) {
        log("JSON Parse Error for topic ${c[0].topic}: $e");
      }
    });
  }

  void _onDisconnected() {
    _updateStatus("Disconnected");
  }

  void _updateStatus(String msg) {
    _statusController.add(msg);
  }

  void disconnect() {
    _client?.disconnect();
  }

  void dispose() {
    _client?.disconnect();
    _statusController.close();
    _messageController.close();
  }
}