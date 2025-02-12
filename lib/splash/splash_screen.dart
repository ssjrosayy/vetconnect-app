import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../homepage.dart';
import '../home_page_for_pets.dart';
import '../login_page.dart';
import '../vet_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        return;
      }

      final userData = userDoc.data()!;
      if (userData['role'] == 'VET') {
        final vetDoc = await FirebaseFirestore.instance
            .collection('vets')
            .doc(user.uid)
            .get();

        if (!vetDoc.exists) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          return;
        }

        final vetData = vetDoc.data()!;
        final currentVet = VetModel(
          id: user.uid,
          name: vetData['name'] ?? '',
          specialization: vetData['specialization'] ?? '',
          experience: vetData['experience'] ?? '',
          location: vetData['location'] ?? '',
          about: vetData['about'] ?? '',
          phoneNumber: vetData['phoneNumber'] ?? '',
          email: vetData['email'] ?? '',
          website: vetData['website'] ?? '',
          openingTime: vetData['openingTime'] ?? '',
          closingTime: vetData['closingTime'] ?? '',
          imagePath: vetData['imagePath'] ?? '',
          isEmergencyAvailable: vetData['isEmergencyAvailable'] ?? false,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(currentVet: currentVet)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePageForPets()),
        );
      }
    } catch (e) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
