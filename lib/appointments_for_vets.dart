import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'view_booked_pets.dart';

class AppointmentsForVetsPage extends StatefulWidget {
  final String vetId;

  const AppointmentsForVetsPage({super.key, required this.vetId});

  @override
  State<AppointmentsForVetsPage> createState() =>
      _AppointmentsForVetsPageState();
}

class _AppointmentsForVetsPageState extends State<AppointmentsForVetsPage> {
  Future<List<Map<String, dynamic>>> _fetchPetsWithAppointments() async {
    // Fetch all confirmed appointments for this vet
    QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vetId', isEqualTo: widget.vetId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    List<Map<String, dynamic>> petsWithAppointments = [];

    for (var doc in appointmentSnapshot.docs) {
      var appointmentData = doc.data() as Map<String, dynamic>;
      var petId = appointmentData['petId'];

      // Fetch pet details
      var petSnapshot =
          await FirebaseFirestore.instance.collection('pets').doc(petId).get();

      // Fetch pet's medical records
      var recordsSnapshot = await FirebaseFirestore.instance
          .collection('medical_records')
          .where('petId', isEqualTo: petId)
          .get();

      if (petSnapshot.exists) {
        var petData = petSnapshot.data() as Map<String, dynamic>;
        petsWithAppointments.add({
          'appointmentId': doc.id,
          'appointmentDetails': appointmentData,
          'petDetails': petData,
          'petOwnerEmail': appointmentData['petOwnerEmail'],
          'medicalRecords':
              recordsSnapshot.docs.map((doc) => doc.data()).toList(),
        });
      }
    }
    return petsWithAppointments;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Appointments & Pet Records"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Current Appointments"),
              Tab(text: "Previous Appointments"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentsList(context, true), // Current appointments
            _buildAppointmentsList(context, false), // Previous appointments
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, bool isCurrent) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPetsWithAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No appointments found"));
        }

        var appointments = snapshot.data!;
        if (!isCurrent) {
          appointments = appointments.where((appointment) {
            DateTime appointmentDate =
                (appointment['appointmentDetails']['date'] as Timestamp)
                    .toDate();
            return appointmentDate.isBefore(DateTime.now());
          }).toList();
        } else {
          appointments = appointments.where((appointment) {
            DateTime appointmentDate =
                (appointment['appointmentDetails']['date'] as Timestamp)
                    .toDate();
            return appointmentDate.isAfter(DateTime.now());
          }).toList();
        }

        return ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            var appointment = appointments[index];
            var pet = appointment['petDetails'];
            var records = appointment['medicalRecords'];

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                leading: pet['imagePath'] != null
                    ? Image.network(
                        pet['imagePath'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.pets, size: 50),
                title: Text(pet['petName'] ?? "Unknown Pet"),
                subtitle: Text("Owner: ${appointment['petOwnerEmail']}\n"
                    "Category: ${pet['petCategory']}\n"
                    "Appointment: ${(appointment['appointmentDetails']['date'] as Timestamp).toDate().toString().split('.')[0]}"),
                children: [
                  ListTile(
                    title: const Text("View Full Details"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailsWithRecordsPage(
                            petDetails: pet,
                            medicalRecords: records,
                            appointmentDetails:
                                appointment['appointmentDetails'],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// New widget to display pet details and records
class PetDetailsWithRecordsPage extends StatelessWidget {
  final Map<String, dynamic> petDetails;
  final List<dynamic> medicalRecords;
  final Map<String, dynamic> appointmentDetails;

  const PetDetailsWithRecordsPage({
    super.key,
    required this.petDetails,
    required this.medicalRecords,
    required this.appointmentDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(petDetails['petName'] ?? "Pet Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (petDetails['imagePath'] != null)
              Center(
                child: Image.network(
                  petDetails['imagePath'],
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            _buildSection("Pet Information", [
              _buildInfoRow("Name", petDetails['petName']),
              _buildInfoRow("Category", petDetails['petCategory']),
              _buildInfoRow("Age", petDetails['petAge']),
              _buildInfoRow("Gender", petDetails['petGender']),
              _buildInfoRow("Weight",
                  "${petDetails['petWeight']} ${petDetails['petWeightUnit']}"),
              _buildInfoRow("Color", petDetails['petColor']),
              _buildInfoRow("Breed", petDetails['petBreed']),
            ]),
            const SizedBox(height: 16),
            _buildSection(
              "Medical Records",
              medicalRecords
                  .map((record) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(record['recordType']),
                          subtitle: Text(
                              "Date: ${(record['administrationDate'] as Timestamp).toDate().toString().split('.')[0]}\n"
                              "Notes: ${record['notes']}"),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value ?? "Not specified"),
        ],
      ),
    );
  }
}
