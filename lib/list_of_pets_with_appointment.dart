import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListOfPetsWithAppointmentPage extends StatelessWidget {
  final String vetId;

  const ListOfPetsWithAppointmentPage({super.key, required this.vetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pets with Appointments"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('vetId', isEqualTo: vetId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No appointments found"));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final petName = appointment['petName'];
              final petOwner = appointment['petOwner'];

              return ListTile(
                title: Text(petName),
                subtitle: Text("Owner: $petOwner"),
                leading: const Icon(Icons.pets),
              );
            },
          );
        },
      ),
    );
  }
}
