import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_connect/splash/splash_screen.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'homepage.dart';
import 'home_page_for_pets.dart';
import 'login_page.dart';
import 'services/notification_service.dart';
import 'signup_page.dart';
import 'firebase_options.dart';
import 'package:vet_connect/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Alarm Manager
  await AndroidAlarmManager.initialize();

  // Request necessary permissions
  await Permission.notification.request();
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }

  // Initialize notifications
  await NotificationService.initialize();

  runApp(const VetConnectApp());
}

class VetConnectApp extends StatelessWidget {
  const VetConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetConnect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          primary: const Color(0xFF6750A4),
          secondary: const Color(0xFF03DAC6),
          tertiary: const Color(0xFFEFB8C8),
          background: const Color(0xFFF6F6F6),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF6750A4),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePageForPets(),
      },
    );
  }
}
