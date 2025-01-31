import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details_of_the_vet.dart';

class AppointmentSchedulesPage extends StatelessWidget {
  const AppointmentSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Schedules'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('vets').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vets found"));
          }

          final vets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              final vet = vets[index];
              final vetName = vet['name'];
              final vetDescription = vet['description'];

              return ListTile(
                title: Text(vetName),
                subtitle: Text(vetDescription),
                leading: const Icon(Icons.person),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsOfTheVetPage(vetId: vet.id),
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
