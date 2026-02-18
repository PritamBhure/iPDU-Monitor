import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

// --- CONDITIONAL IMPORT ---
// This line automatically picks the right file!
// It defaults to 'http_client_factory.dart', but if dart.library.io exists (Mobile), it uses mobile.dart
// If dart.library.js_interop exists (Web), it uses web.dart
import '../constant/appConst.dart';
import 'Client/http_client_factory.dart'
if (dart.library.io) 'Client/http_client_mobile.dart'
if (dart.library.js_interop) 'Client/http_client_web.dart';

class iPDUInfoAPI {
  static final iPDUInfoAPI _instance = iPDUInfoAPI._internal();
  factory iPDUInfoAPI() => _instance;
  iPDUInfoAPI._internal();

  Future<bool> updatePduConfig({
    required String ip,
    required String pduName,
    required String location,
    required String contact,
    required String username,
    required String password,
  }) async {
    // 1. Define URL
    final String url = AppConst.updateiPDUInfo;

    try {
      // 2. GET THE CORRECT CLIENT (Mobile or Web)
      final http.Client client = getHttpClient();

      String basicAuth = 'Basic ${base64.encode(utf8.encode('$username:$password'))}';

      Map<String, String> body = {
        "pduName": pduName,
        "contact": contact,
        "location": location,
      };

      log("API Request: $url");

      // 3. Use the Client
      final response = await client.post(
        Uri.parse(url),
        headers: {
          'authorization': basicAuth,
          'content-type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      log("API Response Code: ${response.statusCode}");

      // Close Client when done (optional, but good practice if not reusing heavily)
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