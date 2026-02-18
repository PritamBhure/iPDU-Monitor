// lib/Services/Client/http_client_web.dart
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart'; // Add http dependency if needed

// 1. Web implementation (Browser handles SSL)
http.Client getHttpClient() {
  return http.Client();
}