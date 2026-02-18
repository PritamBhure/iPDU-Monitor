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
import 'locationListScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animations
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

    // 2. Handle Navigation after Delay
    Timer(const Duration(milliseconds: 2500), _handleNavigation);
  }

// --- CENTRAL NAVIGATION HANDLER ---
  void _handleNavigation() {
    // Early exit if widget is gone
    if (!mounted) return;

    if (kIsWeb) {
      // WEB FLOW: Auto-connect based on Browser URL
      _navigateToWebDashboard();
    } else {
      // MOBILE FLOW: Go to Location Selection
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LocationListScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

// --- WEB SPECIFIC LOGIC ---
  void _navigateToWebDashboard() {
    // 1. Logic to get IP (No 'if kIsWeb' needed here, we already know we are on web)
    String browserHost = Uri.base.host;

    // Use Browser IP if valid, otherwise fallback to Test IP
    String targetIP = (browserHost.isNotEmpty && browserHost != "localhost")
        ? browserHost
        : AppConst.baseUrl;

    log("Web Auto-Connect: Detected IP -> $targetIP");

    // 2. Initialize Controller
    final pduDevice = PduDevice(
      id: "Auto-Connect",
      name: "Local PDU",
      ip: targetIP,
      type: PduType.IMIS,
      phase: PhaseType.ThreePhaseStar,
    );

    final controller = PduController(pduDevice);

    // 3. Navigate
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: const DashboardView(),
        ),
      ),
    );

    // 4. Connect
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
