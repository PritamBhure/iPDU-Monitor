import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // <--- Add this// Import your Models
import 'Controller/provider/locationControllerProvider.dart';
import 'Model/pdu_model.dart';
import 'Model/rackModel.dart';
import 'Model/locationModel.dart';

// Import Controllers and Screens
import 'Core/constant/appColors_constant.dart';
import 'View/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive
  await Hive.initFlutter();

  // 3. Register Adapters
  Hive.registerAdapter(PduTypeAdapter());
  Hive.registerAdapter(PhaseTypeAdapter());
  Hive.registerAdapter(PduDeviceAdapter());
  Hive.registerAdapter(RackAdapter());
  Hive.registerAdapter(LocationAdapter());

  // 4. Open the Box
  await Hive.openBox<Location>('locationsBox');
  // 5. Open a Box (Database)
  await Hive.openBox('settings');

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
    // <-- 2. Wrap MaterialApp with ScreenUtilInit
    return ScreenUtilInit(
      designSize: const Size(1440, 900), // Standard laptop/desktop resolution
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Elcom iPDU Monitor',
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: AppColors.backgroundDeep,
            // This applies the local font from pubspec.yaml globally
            textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'JetBrainsMono',
            ),
          ),
          home: child, // <-- 3. Pass the child here
        );
      },
      child: const SplashScreen(), // <-- 4. Your initial screen goes here
    );
  }
}