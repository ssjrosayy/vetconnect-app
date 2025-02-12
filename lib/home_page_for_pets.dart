import 'package:flutter/material.dart';
import 'package:vet_connect/drawer.dart';
import 'package:vet_connect/PetListPage.dart';
import 'appointment_schedules.dart';
import 'online_consultation.dart';
import 'emergency.dart';
import 'vet_profile_page.dart';
import 'vet_model.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageForPets extends StatefulWidget {
  const HomePageForPets({super.key});

  @override
  _HomePageForPetsState createState() => _HomePageForPetsState();
}

class _HomePageForPetsState extends State<HomePageForPets> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Owner Dashboard'),
      ),
      drawer: MyDrawer(
        email: user?.email ?? 'No email',
        profileImageUrl: user?.photoURL ?? 'https://placeholder.com/user',
        onLogout: () async {
          await _auth.signOut();
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: [
          _buildMenuCard(
            'My Pets',
            Icons.pets,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PetListPage()),
            ),
          ),
          _buildMenuCard(
            'Available Vets',
            Icons.medical_services,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('vets').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Something went wrong'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Scaffold(
                      appBar: AppBar(title: const Text('Available Vets')),
                      body: ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final vetData = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                          final vet = VetModel(
                            id: snapshot.data!.docs[index].id,
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
                            isEmergencyAvailable:
                                vetData['isEmergencyAvailable'] ?? false,
                          );

                          return ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(vet.name),
                            subtitle: Text(vet.specialization),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VetProfilePage(
                                    vet: vet,
                                    onUpdate: (VetModel vet) async {
                                      // Refresh the vet list
                                      setState(() {});
                                      Navigator.pop(context);
                                    },
                                    onBookAppointment: () {
                                      showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now()
                                            .add(const Duration(days: 365)),
                                      ).then((selectedDate) async {
                                        if (selectedDate != null) {
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('appointments')
                                                .add({
                                              'vetId': vet.id,
                                              'petOwnerId':
                                                  _auth.currentUser?.uid,
                                              'date': selectedDate,
                                              'status': 'pending',
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Appointment request sent')),
                                            );
                                            Navigator.pop(context);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text('Error: $e')),
                                            );
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildMenuCard(
            'Appointments',
            Icons.calendar_today,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const AppointmentSchedulesPage()), // Changed from AppointmentSchedules
            ),
          ),
          _buildMenuCard(
            'Online Consultation',
            Icons.video_call,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const OnlineConsultationPage()),
            ),
          ),
          _buildMenuCard(
            'Emergency',
            Icons.emergency,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmergencyPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
