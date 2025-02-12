import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'vet_model.dart';
import 'add_vet_page.dart';

class VetProfilePage extends StatelessWidget {
  final VetModel vet;
  final Function(VetModel) onUpdate;
  final VoidCallback onBookAppointment;

  const VetProfilePage({
    Key? key,
    required this.vet,
    required this.onUpdate,
    required this.onBookAppointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dr. ${vet.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vet.imagePath.isNotEmpty)
              Center(
                child: Image.network(
                  vet.imagePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoSection('Specialization', vet.specialization),
            _buildInfoSection('Experience', vet.experience),
            _buildInfoSection('Location', vet.location),
            _buildInfoSection('About', vet.about),
            _buildInfoSection('Contact', vet.phoneNumber),
            _buildInfoSection('Email', vet.email),
            _buildInfoSection('Website', vet.website),
            _buildInfoSection(
                'Working Hours', '${vet.openingTime} - ${vet.closingTime}'),
            const SizedBox(height: 16),
            if (vet.isEmergencyAvailable)
              const Chip(
                label: Text('Emergency Available'),
                backgroundColor: Colors.red,
                labelStyle: TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // First get available slots
                  final slotsDoc = await FirebaseFirestore.instance
                      .collection('vets')
                      .doc(vet.id)
                      .collection('slots')
                      .doc('schedule')
                      .get();

                  if (!slotsDoc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No available slots')),
                    );
                    return;
                  }

                  final slots = slotsDoc.data()?['slots'] as List<dynamic>;

                  // Show slot selection dialog
                  final selectedSlot = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Select Time Slot'),
                      children: slots.map<SimpleDialogOption>((slot) {
                        return SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, slot),
                          child: Text(slot),
                        );
                      }).toList(),
                    ),
                  );

                  if (selectedSlot != null) {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );

                    if (selectedDate != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('appointments')
                            .add({
                          'vetId': vet.id,
                          'vetName': vet.name,
                          'petOwnerId': FirebaseAuth.instance.currentUser?.uid,
                          'ownerName':
                              FirebaseAuth.instance.currentUser?.displayName,
                          'date': selectedDate,
                          'slot': selectedSlot,
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Appointment request sent')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}
