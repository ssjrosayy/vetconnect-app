import 'package:flutter/material.dart';
import 'dart:io';

import 'vet_model.dart';
import 'add_vet_page.dart';

class VetProfilePage extends StatelessWidget {
  final VetModel vet;
  final Function(VetModel) onUpdate;

  const VetProfilePage({super.key, 
    required this.vet,
    required this.onUpdate, required Null Function() onBookAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVetPage(
                    onSave: (updatedVet) {
                      onUpdate(updatedVet);
                      Navigator.pop(context);
                    },
                    vet: vet,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child:
                  vet.imagePath.isNotEmpty && File(vet.imagePath).existsSync()
                      ? Image.file(
                          File(vet.imagePath),
                          height: 300,
                          width: 400,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/default_vet_image.png',
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                        ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 255, 254, 254)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                'Dr. ${vet.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: const Color.fromARGB(255, 251, 251, 251)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8.0),
                  Text(
                    vet.address,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 255, 252, 252)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8.0),
                  Text(
                    'Opens at ${vet.openingTime}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 255, 253, 253)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.web),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      vet.website,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone),
                  const SizedBox(width: 8.0),
                  Text(
                    vet.phone,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email),
                  const SizedBox(width: 8.0),
                  Text(
                    vet.email,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
