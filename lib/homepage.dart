import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vet_connect/drawer.dart';
import 'PetListPage.dart';
import 'online_consultation.dart';
import 'emergency.dart';
import 'vet_profile_page.dart'; // Import the VetProfilePage
import 'add_vet_page.dart';
import 'vet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the new page
import 'appointments_for_vets.dart';
import 'manage_time_slots_page.dart';
import 'screens/chat_list_screen.dart';

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String appointmentId;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    required this.appointmentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Pet Owner: ${appointment['ownerName']}'),
        subtitle:
            Text('Date: ${appointment['date']}\nTime: ${appointment['time']}'),
        trailing: Text(appointment['status']),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VetModel currentVet;

  const HomePage({
    Key? key,
    required this.currentVet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${currentVet.name}\'s Dashboard'),
      ),
      drawer: MyDrawer(
        email: currentVet.email,
        profileImageUrl: currentVet.imagePath,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildDashboardItem(
            context,
            'Appointments',
            Icons.calendar_today,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AppointmentsForVetsPage(vetId: currentVet.id),
                ),
              );
            },
          ),
          _buildDashboardItem(
            context,
            'Profile',
            Icons.person,
            () {
              // Navigate to profile
            },
          ),
          _buildDashboardItem(
            context,
            'Consultations',
            Icons.medical_services,
            () {
              // Navigate to consultations
            },
          ),
          _buildDashboardItem(
            context,
            'Emergency Cases',
            Icons.emergency,
            () {
              // Navigate to emergency cases
            },
          ),
          _buildDashboardItem(
            context,
            'Messages',
            Icons.message,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatListScreen(
                    currentUserId: currentVet.id,
                    isVet: true,
                    currentUserName: currentVet.name,
                  ),
                ),
              );
            },
          ),
          _buildDashboardItem(
            context,
            'Settings',
            Icons.settings,
            () {
              // Navigate to settings
            },
          ),
          _buildDashboardItem(
            context,
            'Manage Slots',
            Icons.schedule,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ManageTimeSlotsPage(vetId: currentVet.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
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
