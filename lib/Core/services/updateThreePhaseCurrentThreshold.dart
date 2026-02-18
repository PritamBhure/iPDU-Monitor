import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// Conditional Import for SSL Bypass (Same as before)
import '../constant/appConst.dart';
import 'Client/http_client_factory.dart'
if (dart.library.io) 'Client/http_client_mobile.dart'
if (dart.library.js_interop) 'Client/http_client_web.dart';

class ElectricalThresholdAPI {
  static final ElectricalThresholdAPI _instance = ElectricalThresholdAPI._internal();
  factory ElectricalThresholdAPI() => _instance;
  ElectricalThresholdAPI._internal();

  Future<bool> updateThresholds({
    required String ip,
    required String username,
    required String password,
    required Map<String, String> thresholds, // Pass the JSON body map directly
  }) async {
    final String url = AppConst.threePhaseCurrentThreshold;

    try {
      final http.Client client = getHttpClient();
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      log("API Request: $url");
      log("Body: $thresholds");

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'authorization': basicAuth,
          'content-type': 'application/json',
        },
        body: jsonEncode(thresholds),
      ).timeout(const Duration(seconds: 10));

      log("API Response Code: ${response.statusCode}");
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