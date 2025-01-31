import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentOptionsPage extends StatelessWidget {
  final String vetName;
  final DateTime dateTime;
  final int fee;
  final String vetId;
  final String petOwnerEmail;  // Add email of the pet owner

  const PaymentOptionsPage({super.key, 
    required this.vetName,
    required this.dateTime,
    required this.fee,
    required this.vetId,
    required this.petOwnerEmail,  // Pass the email of the pet owner
  });

  Future<void> _saveAppointment(String paymentMethod, BuildContext context) async {
    final appointmentRef = FirebaseFirestore.instance.collection('appointments').doc();
    
    // Set appointment data
    await appointmentRef.set({
      'vetId': vetId,
      'vetName': vetName,
      'date': dateTime,
      'time': TimeOfDay.fromDateTime(dateTime).format(context),
      'fee': fee,
      'paymentMethod': paymentMethod,
      'paymentStatus': 'Confirmed', // Confirm appointment directly
      'petOwnerEmail': petOwnerEmail,  // Store pet owner's email
      'status': 'confirmed', // Set the status to confirmed
    });

    // Navigate to confirmation screen or show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Appointment Confirmed"),
        content: const Text("Your appointment is confirmed. Please pay at the clinic."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Options"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Vet: $vetName", style: const TextStyle(fontSize: 20)),
            Text("Appointment Date: ${dateTime.toLocal().toString().split(' ')[0]}"),
            Text("Time: ${TimeOfDay.fromDateTime(dateTime).format(context)}"),
            Text("Fee: $fee Rs", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _saveAppointment("Pay at Clinic", context),  // Remove online payment option
              child: const Text("Pay at Clinic"),
            ),
          ],
        ),
      ),
    );
  }
}
