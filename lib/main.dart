import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vet_connect/splash/splash_screen.dart';
import 'homepage.dart';
import 'home_page_for_pets.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VetConnectApp());
}

class VetConnectApp extends StatelessWidget {
  const VetConnectApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetConnect',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/homeForPets': (context) => const HomePageForPets(),
      },
    );
  }
}
