import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewBookedPetPage extends StatelessWidget {
  final String petId;

  const ViewBookedPetPage({super.key, required this.petId});

  Future<Map<String, dynamic>?> _fetchPetDetails() async {
    // Fetch pet details from Firebase
    DocumentSnapshot petSnapshot =
        await FirebaseFirestore.instance.collection('pets').doc(petId).get();
    if (petSnapshot.exists) {
      return petSnapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pet Profile")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchPetDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load pet details"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Pet details not available"));
          }

          // Build pet details UI
          var pet = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Center(
                  child: pet['imageUrl'] != null
                      ? Image.network(
                          pet['imageUrl'],
                          height: 300,
                          width: 300,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.pets, size: 100),
                ),
                const SizedBox(height: 20),
                Text(
                  "Name: ${pet['name']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "Category: ${pet['category']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "Age: ${pet['age']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "Breed: ${pet['breed']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  "Owner's Notes: ${pet['notes']}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                // Add more fields as necessary
              ],
            ),
          );
        },
      ),
    );
  }
}
