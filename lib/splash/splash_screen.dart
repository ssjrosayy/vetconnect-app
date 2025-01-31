import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vet_connect/home_page_for_pets.dart';
import 'package:vet_connect/homepage.dart';
import 'package:vet_connect/login_page.dart';
import '../vet_connect_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    //Future Delayed Used For Asynchronous Values
    Future.delayed(
      Duration.zero,
      () async {
        //Get Current User
        User? user = FirebaseAuth.instance.currentUser;

        //Initialize SharedPreference
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        //Check Current User Type Stored In Local Database
        String? userType = prefs.getString('userType');
        //Check User Authenticated
        if (user != null) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .then(
            (currentUserData) {
              print(
                currentUserData.data()?['role'],
              );
              final String userType = currentUserData.data()?['role'];
              //Check UserType & When UserType is VET
              if (userType == 'VET') {
                Timer(
                  //3 Seconds Timer
                  const Duration(
                    seconds: 3,
                  ),
                  //Go To HomePage Of VET
                  () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) => HomePage(),
                    ),
                  ),
                );
              }
              //Check UserType & When UserType is PET
              else {
                Timer(
                  //3 Seconds Timer
                  const Duration(
                    seconds: 3,
                  ),
                  //Go To HomePage Of PET
                  () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) => HomePageForPets(),
                    ),
                  ),
                );
              }
            },
          );
        }

        //User Not Authenticated
        else {
          Timer(
            //3 Seconds Timer
            const Duration(
              seconds: 3,
            ),
            //Go To LoginPage
            () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => LoginPage(),
              ),
            ),
          );
        }
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: VetConnectPainter(),
        ),
      ),
    );
  }
}
