// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\mobile_app\lib\main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/staff_dashboard.dart';
import 'screens/guard_dashboard.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOD Gatekeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Deep Blue matching IOD theme
          brightness: Brightness.light,
        ),
        fontFamily: 'Outfit', // Match typography
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Outfit',
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Dark/Light system sync
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/staff': (context) => const StaffDashboard(),
        '/guard': (context) => const GuardDashboard(),
      },
    );
  }
}
