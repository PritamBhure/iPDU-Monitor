import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:pdu_control_system/Core/constant/appConst.dart';

// Conditional Import for SSL Bypass
import 'Client/http_client_factory.dart'
if (dart.library.io) 'Client/http_client_mobile.dart'
if (dart.library.js_interop) 'Client/http_client_web.dart';

class SensorThresholdAPI {
  static final SensorThresholdAPI _instance = SensorThresholdAPI._internal();
  factory SensorThresholdAPI() => _instance;
  SensorThresholdAPI._internal();

  Future<bool> updateSensorConfig({
    required String ip,
    required String username,
    required String password,
    required Map<String, String> configData,
  }) async {
    // TODO: Verify this Endpoint URL with your backend team
    final String url = AppConst.updateSensorConfig;

    try {
      final http.Client client = getHttpClient();
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      log("API Request: $url");
      // log("Sending paylod: $configData");
      log("Sending paylaod : ${configData.toString()}");

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'authorization': basicAuth,
          'content-type': 'application/json',
        },

        body: jsonEncode(configData),
      ).timeout(const Duration(seconds: 10));

      log("API Response Code: ${response.statusCode}");

      // log("Sending paylaod : ${jsonDecode(response.body)}");
      client.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        log("API Error: ${response.body}");
        return false;
      }
    } catch (e) {
      log("API Exception: $e");
      return false;
    }
  }
}