import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vet_connect/view_booked_pets.dart';

class AppointmentsForVetsPage extends StatelessWidget {
  final String vetId;

  const AppointmentsForVetsPage({super.key, required this.vetId});

  Future<List<Map<String, dynamic>>> _fetchConfirmedAppointments() async {
    // Fetch confirmed appointments for the logged-in vet
    QuerySnapshot appointmentSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vetId', isEqualTo: vetId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    // Map the appointment data with pet details
    List<Map<String, dynamic>> appointments = [];
    for (var doc in appointmentSnapshot.docs) {
      var appointmentData = doc.data() as Map<String, dynamic>;
      var petId = appointmentData['petId'];

      // Fetch pet details from pet collection
      var petSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .doc(petId)
          .get();
      if (petSnapshot.exists) {
        var petData = petSnapshot.data() as Map<String, dynamic>;
        appointments.add({
          'appointmentId': doc.id,
          'appointmentDetails': appointmentData,
          'petDetails': petData,
          'petOwnerEmail': appointmentData['petOwnerEmail'], // Add pet owner's email
        });
      }
    }
    return appointments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmed Appointments")),
      body: FutureBuilder<List<Map<String, dynamic>>>(  // Display confirmed appointments
        future: _fetchConfirmedAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load appointments"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No confirmed appointments"));
          }

          // Build a list of appointments
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var appointment = snapshot.data![index];
              var pet = appointment['petDetails'];
              var petOwnerEmail = appointment['petOwnerEmail'];  // Get email

              return ListTile(
                leading: pet['imageUrl'] != null
                    ? Image.network(
                        pet['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.pets, size: 50),
                title: Text(pet['name'] ?? "Pet"),
                subtitle: Text('Owner Email: $petOwnerEmail\nCategory: ${pet['category'] ?? "Unknown"}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewBookedPetPage(petId: pet['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
