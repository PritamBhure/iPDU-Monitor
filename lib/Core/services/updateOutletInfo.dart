import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// Conditional Import for SSL Bypass
import '../constant/appConst.dart';
import 'Client/http_client_factory.dart'
if (dart.library.io) 'Client/http_client_mobile.dart'
if (dart.library.js_interop) 'Client/http_client_web.dart';

class OutletAPI {
  static final OutletAPI _instance = OutletAPI._internal();
  factory OutletAPI() => _instance;
  OutletAPI._internal();

  Future<bool> updateOutletNames({
    required String ip,
    required String username,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    // Note: Verify the endpoint. Prompt said "updateOutlets" in one place
    // and defined "updateSensorConfig" in AppConst. Using the prompt URL.
    final String url = AppConst.updateOutletNames;

    try {
      final http.Client client = getHttpClient();
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      log("API Request: $url");
      log("Body: $data");

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'authorization': basicAuth,
          'content-type': 'application/json',
        },
        body: jsonEncode(data),
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


  Future<bool> updateThresholds({
    required String ip,
    required String username,
    required String password,
    required List<Map<String, dynamic>> payload,
  }) async {
    final String url = AppConst.updateOutletThresholds;


    try {
      final http.Client client = getHttpClient();
      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      log("API Request: $url");
      log("Body: $payload");

      final response = await client.post(
        Uri.parse(url),
        headers: {
          'authorization': basicAuth,
          'content-type': 'application/json',
        },
        body: jsonEncode(payload),
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