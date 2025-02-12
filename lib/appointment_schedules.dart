import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('petOwnerId',
                isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!.docs;

          if (appointments.isEmpty) {
            return const Center(child: Text('No appointments yet'));
          }

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment =
                  appointments[index].data() as Map<String, dynamic>;
              final date = (appointment['date'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Dr. ${appointment['vetName']}'),
                  subtitle: Text('Date: ${date.toString().split(' ')[0]}\n'
                      'Time: ${appointment['slot']}\n'
                      'Status: ${appointment['status']}'),
                  trailing: appointment['status'] == 'pending'
                      ? const Chip(label: Text('Pending'))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
