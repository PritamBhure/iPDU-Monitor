import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
import 'package:provider/provider.dart';

// Import your Models
import 'Controller/provider/locationControllerProvider.dart';
import 'Model/pdu_model.dart';
import 'Model/rackModel.dart';
import 'Model/locationModel.dart';

// Import Controllers and Screens
import 'Core/constant/appColors_constant.dart';
import 'View/splashScreen.dart';

void main() async {
  // 1. Ensure Widgets Binding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Register Adapters (Order matters, match typeId)
  Hive.registerAdapter(PduTypeAdapter());
  Hive.registerAdapter(PhaseTypeAdapter());
  Hive.registerAdapter(PduDeviceAdapter());
  Hive.registerAdapter(RackAdapter());
  Hive.registerAdapter(LocationAdapter());

  // 4. Open the Box (The actual database file)
  await Hive.openBox<Location>('locationsBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationController()),
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
      title: 'Industrial PDU Monitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.backgroundDeep,
        textTheme: GoogleFonts.jetBrainsMonoTextTheme(),

      ),
      home: const SplashScreen(),
    );
  }
}