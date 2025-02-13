import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PetListPage.dart';
import 'appointment_schedules.dart';
import 'online_consultation.dart';
import 'emergency.dart';
import 'vet_profile_page.dart';
import 'vet_model.dart';
import 'screens/ai_diagnosis_screen.dart';
import 'screens/pet_chatbot_screen.dart';

class HomePageForPets extends StatefulWidget {
  const HomePageForPets({super.key});

  @override
  _HomePageForPetsState createState() => _HomePageForPetsState();
}

class _HomePageForPetsState extends State<HomePageForPets> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Pet Owner Dashboard'),
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
            _buildWelcomeCard(user),
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

  Widget _buildWelcomeCard(User? user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
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
                    user?.displayName ?? 'Pet Owner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    user?.email ?? '',
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
          .collection('pets')
          .where('uid', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, petsSnapshot) {
        int totalPets = 0;
        if (petsSnapshot.hasData) {
          totalPets = petsSnapshot.data!.docs.length;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('petOwnerId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, appointmentsSnapshot) {
            int pendingAppointments = 0;
            if (appointmentsSnapshot.hasData) {
              pendingAppointments = appointmentsSnapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'pending')
                  .length;
            }

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total\nPets',
                    totalPets.toString(),
                    Icons.pets,
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
          'My Pets',
          Icons.pets,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PetListPage()),
          ),
          Theme.of(context).colorScheme.primary,
        ),
        _buildDashboardItem(
          'Available Vets',
          Icons.medical_services,
          () => _showAvailableVets(),
          Theme.of(context).colorScheme.secondary,
        ),
        _buildDashboardItem(
          'Appointments',
          Icons.calendar_today,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AppointmentSchedulesPage()),
          ),
          Theme.of(context).colorScheme.tertiary,
        ),
        _buildDashboardItem(
          'Online Consultation',
          Icons.video_call,
          () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const OnlineConsultationPage()),
          ),
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        _buildDashboardItem(
          'Emergency',
          Icons.emergency,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyPage()),
          ),
          Theme.of(context).colorScheme.error,
        ),
        _buildDashboardItem(
          'AI Diagnosis',
          Icons.analytics_outlined,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIDiagnosisScreen()),
          ),
          Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ),
        _buildDashboardItem(
          'Pet Care Assistant',
          Icons.chat,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PetChatbotScreen(),
            ),
          ),
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
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

  void _showAvailableVets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('vets').snapshots(),
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
                  final vetData =
                      snapshot.data!.docs[index].data() as Map<String, dynamic>;
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

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: vet.imagePath.isNotEmpty
                            ? NetworkImage(vet.imagePath)
                            : null,
                        child: vet.imagePath.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        'Dr. ${vet.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vet.specialization),
                          Text('Experience: ${vet.experience}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VetProfilePage(
                              vet: vet,
                              onUpdate: (VetModel vet) async {
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
                                        'petOwnerId': _auth.currentUser?.uid,
                                        'date': selectedDate,
                                        'status': 'pending',
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Appointment request sent'),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
