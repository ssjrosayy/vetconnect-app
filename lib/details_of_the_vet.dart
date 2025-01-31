import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'make_appointment_with_vet.dart';

class DetailsOfTheVetPage extends StatelessWidget {
  final String vetId;

  const DetailsOfTheVetPage({super.key, required this.vetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vet Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('vets').doc(vetId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Vet details not found"));
          }

          final vet = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final vetName = vet['name'] ?? 'No name available';
          final vetDescription = vet['description'] ?? 'No description available';
          final vetAddress = vet['address'] ?? 'No address available';
          final vetPhoneNumber = vet['phone'] ?? 'No phone number available';
          final vetEmail = vet['email'] ?? 'No email available';
          final vetImage = vet['imageUrl'];
          final fee = vet['fee'] ?? 'Not available';
          final availableSlots = (vet['availableSlots'] as List<dynamic>?)?.cast<String>() ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vetImage != null)
                  Center(
                    child: Image.network(
                      vetImage,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Dr. $vetName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vetDescription,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Address: $vetAddress',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: $vetPhoneNumber',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: $vetEmail',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consultation Fee: \$${fee.toString()}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Available Time Slots:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: availableSlots.map((slot) {
                    return Chip(
                      label: Text(slot),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MakeAppointmentWithVetPage(vetId: vetId),
                        ),
                      );
                    },
                    child: const Text("Book Now"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
