import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

// Import Controller, Model, and Dashboard
import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appConst.dart';
import '../Model/pdu_model.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appImageConst.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after animation finishes (2.5 seconds total)
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    String targetIP;

    // --- DYNAMIC IP LOGIC ---
    if (kIsWeb) {
      // 1. Get the Hostname from the Browser URL (e.g., 192.168.8.200)
      String browserHost = Uri.base.host;
      log("I am trying to getting IP");

      // 2. Check if valid (Not empty, not localhost for production)
      if (browserHost.isNotEmpty && browserHost != "localhost") {
        targetIP = browserHost;
      } else {
        log("IP is empty or localhost.");

        // Fallback for local testing if needed
        targetIP = AppConst.puneIp1;
      }
    } else {
      // Mobile Fallback
      targetIP = AppConst.puneIp1;
    }

    log("Auto-Connecting to IP: $targetIP"); // Debug log

    // 1. Create PDU Device with dynamic IP
    final pduDevice = PduDevice(
      id: "Auto-Connect",
      name: "Local PDU",
      ip: targetIP,
      type: PduType.IMIS,
      phase: PhaseType.ThreePhaseStar,
    );

    // 2. Initialize Controller
    final controller = PduController(pduDevice);

    // 3. Navigate to Dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: const DashboardView(),
        ),
      ),
    );

    // 4. Trigger Connection
    controller.connectToBroker(targetIP, "elcom@2021", "elcomMQ@2022");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.logoBG,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 200,
              height: 200,
              child: SvgPicture.asset(
                AppImages.primaryLogoSvg,
                width: 500,
                height: 500,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}