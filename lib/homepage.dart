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
import 'package:intl/intl.dart';
import 'edit_vet_profile_page.dart';
import 'list_of_pets_with_appointment.dart';

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

class HomePage extends StatefulWidget {
  final VetModel currentVet;

  const HomePage({Key? key, required this.currentVet}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Vet Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDashboardGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.currentVet.imagePath.isNotEmpty
                  ? NetworkImage(widget.currentVet.imagePath)
                  : null,
              child: widget.currentVet.imagePath.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Dr. ${widget.currentVet.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    widget.currentVet.specialization,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('vetId', isEqualTo: widget.currentVet.id)
          .snapshots(),
      builder: (context, snapshot) {
        int totalAppointments = 0;
        int pendingAppointments = 0;

        if (snapshot.hasData) {
          totalAppointments = snapshot.data!.docs.length;
          pendingAppointments = snapshot.data!.docs
              .where((doc) => (doc.data() as Map)['status'] == 'pending')
              .length;
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total\nAppointments',
                totalAppointments.toString(),
                Icons.calendar_today,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending\nAppointments',
                pendingAppointments.toString(),
                Icons.pending_actions,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildDashboardItem(
          'Appointments',
          Icons.calendar_today,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AppointmentsForVetsPage(vetId: widget.currentVet.id),
            ),
          ),
          Theme.of(context).colorScheme.primary,
        ),
        _buildDashboardItem(
          'Profile',
          Icons.person,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VetProfilePage(
                vet: widget.currentVet,
                onUpdate: (updatedVet) async {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(currentVet: updatedVet),
                    ),
                  );
                },
                onBookAppointment: () {},
              ),
            ),
          ),
          Theme.of(context).colorScheme.secondary,
        ),
        _buildDashboardItem(
          'Pet List',
          Icons.pets,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ListOfPetsWithAppointmentPage(vetId: widget.currentVet.id),
            ),
          ),
          Theme.of(context).colorScheme.tertiary,
        ),
        _buildDashboardItem(
          'Time Slots',
          Icons.access_time,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageTimeSlotsPage(vetId: widget.currentVet.id),
            ),
          ),
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        _buildDashboardItem(
          'Messages',
          Icons.message,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListScreen(
                currentUserId: widget.currentVet.id,
                isVet: true,
                currentUserName: widget.currentVet.name,
              ),
            ),
          ),
          Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildDashboardItem(
    String title,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<VetModel> _refreshVetData(String vetId) async {
    final vetDoc =
        await FirebaseFirestore.instance.collection('vets').doc(vetId).get();

    final data = vetDoc.data() as Map<String, dynamic>;
    return VetModel(
      id: vetId,
      name: data['name'] ?? '',
      specialization: data['specialization'] ?? '',
      experience: data['experience'] ?? '',
      location: data['location'] ?? '',
      about: data['about'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      openingTime: data['openingTime'] ?? '',
      closingTime: data['closingTime'] ?? '',
      imagePath: data['imagePath'] ?? '',
      isEmergencyAvailable: data['isEmergencyAvailable'] ?? false,
    );
  }
}
