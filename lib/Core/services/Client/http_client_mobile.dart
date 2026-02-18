// lib/Services/Client/http_client_mobile.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// 1. Mobile implementation with SSL Bypass
http.Client getHttpClient() {
  final ioc = HttpClient();
  ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  return IOClient(ioc);
}