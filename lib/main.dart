import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'Controller/provider/locationControllerProvider.dart';
import 'Controller/provider/pdu_provider.dart';
import 'Core/constant/appColors_constant.dart';
import 'View/dashboard_screen.dart';
import 'View/locationListScreen.dart';
import 'View/splashScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Register the LocationController here
        ChangeNotifierProvider(create: (_) => LocationController()),
        // Add other providers as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elcom iPDU Monitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.backgroundDeep,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}