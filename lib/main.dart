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
        primarySwatch: Colors.blue,
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
