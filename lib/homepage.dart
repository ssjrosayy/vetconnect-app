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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch vet data as a stream from Firestore
  Stream<List<VetModel>> _fetchVets() {
    final userId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user UID
    return _firestore
        .collection('vets')
        .where('userId', isEqualTo: userId) // Filter by UID
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var vet = VetModel.fromJson(doc.data());
              vet.id = doc.id; // Assign document ID to vet
              return vet;
            }).toList());
  }

  void _addOrEditVet([VetModel? vet]) {
    final userId =
        FirebaseAuth.instance.currentUser!.uid; // Get current user UID
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddVetPage(
          onSave: (vet) async {
            final vetData = vet.toJson();
            vetData['userId'] = userId; // Add userId field

            if (vet.id.isNotEmpty) {
              // Update vet
              await _firestore.collection('vets').doc(vet.id).update(vetData);
            } else {
              // Add new vet
              await _firestore.collection('vets').add(vetData);
            }
          },
          vet: vet,
        ),
      ),
    );
  }

  void _deleteVet(String vetId) async {
    // Delete the vet from Firestore
    await _firestore.collection('vets').doc(vetId).delete();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<List<VetModel>>(
          stream: _fetchVets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text('No vets to delete.'));
            }

            final vets = snapshot.data!;
            return AlertDialog(
              title: const Text('Select Profile to Delete'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vets.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(vets[index].name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteVet(vets[index].id); // Delete from Firestore
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(VetModel vet) {
    _addOrEditVet(vet); // Opens the AddVetPage with vet data for editing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VetConnect'),
        actions: [
          TextButton(
            onPressed: () {
              _addOrEditVet(); // Open AddVetPage for adding a new vet
            },
            child: const Text(
              'Add profile',
              style: TextStyle(
                  color: Color.fromARGB(255, 207, 82, 230), fontSize: 16),
            ),
          ),
        ],
      ),
      drawer: MyDrawer(
        email: "user@example.com", // Replace with dynamic data
        profileImageUrl: "https://www.example.com/profile.jpg",
        onLogout: () {}, // Replace with dynamic data
      ),
      body: StreamBuilder<List<VetModel>>(
        stream: _fetchVets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final vets = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.orange.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Take care of pet\'s health\nyour pet is important',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryButton(
                      context,
                      Icons.schedule,
                      'appointment\nschedules',
                      const AppointmentsForVetsPage(vetId: "sampleVetId"),
                    ),
                    const SizedBox(width: 10),
                    _buildCategoryButton(
                      context,
                      Icons.chat,
                      'online\nconsultation',
                      const OnlineConsultationPage(),
                    ),
                    const SizedBox(width: 10),
                    _buildCategoryButton(
                      context,
                      Icons.pets,
                      'pet\nprofiles',
                      const PetListPage(),
                    ),
                    const SizedBox(width: 10),
                    _buildCategoryButton(
                      context,
                      Icons.local_hospital,
                      'emergency',
                      const EmergencyPage(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Veterinary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _showDeleteDialog,
                child: const Text(
                  'Delete profile',
                  style: TextStyle(
                      color: Color.fromARGB(255, 255, 0, 0), fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: vets.length,
                itemBuilder: (context, index) {
                  return _buildVeterinaryCard(context, vets[index]);
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today, size: 22),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 26),
            label: '',
          ),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context, IconData icon, String label, Widget page) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(icon),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },
            iconSize: 50,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVeterinaryCard(BuildContext context, VetModel vet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VetProfilePage(
              vet: vet,
              onUpdate: (updatedVet) => _addOrEditVet(updatedVet),
              onBookAppointment: () {},
            ),
          ),
        );
      },
      onLongPress: () {
        _showEditDialog(vet);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.purple.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              //ClipOval(
              //child: vet.imagePath != null && vet.imagePath.isNotEmpty
              //? Image.network(
              // vet.imagePath,
              // width: 80,
              //height: 80,
              // fit: BoxFit.cover,
              //errorBuilder: (context, error, stackTrace) {
              // Fallback to default image if URL fails
              //return Image.asset(
              //'assets/default_vet_image.png',
              //width: 80,
              // height: 80,
              // fit: BoxFit.cover,
              //);
              //},
              //)
              //: //Image.asset(
              //'assets/default_vet_image.png',
              //width: 80,
              //height: 80,
              //fit: BoxFit.cover,
              //),
              //),
              const SizedBox(height: 8),
              Text(
                'Dr. ${vet.name}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    vet.address,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
