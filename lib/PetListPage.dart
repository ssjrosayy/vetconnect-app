import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'PetDetailsPage.dart';

class PetListPage extends StatefulWidget {
  const PetListPage({super.key});

  @override
  _PetListPageState createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID
    final String? uid = auth.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pet List'),
        ),
        body: const Center(
          child: Text('No user is logged in'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pets'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('pets')
            .where('uid', isEqualTo: uid) // Filter by the logged-in user's UID
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching pet data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pets added yet.'));
          }

          final pets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final petData = pets[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: petData['imagePath'] != null
                      ? Image.network(
                          petData['imagePath'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.pets),
                  title: Text(petData['petName'] ?? 'Unnamed Pet'),
                  subtitle: Text('${petData['petCategory']}, ${petData['petAge']} years old'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to PetDetailsPage for editing
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailsPage(
                            pet: petData.map((key, value) => MapEntry(key, value.toString())),
                            onSave: (updatedPet) {
                              // Update the pet data in Firestore
                              firestore
                                  .collection('pets')
                                  .doc(petData['id'])
                                  .update(updatedPet)
                                  .then((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pet details updated successfully')),
                                );
                              }).catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error updating pet: $error')),
                                );
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to PetDetailsPage for adding a new pet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailsPage(
                pet: const {},
                onSave: (newPet) {
                  // Save new pet data to Firestore with UID
                  final String id = DateTime.now().microsecondsSinceEpoch.toString();
                  firestore.collection('pets').doc(id).set({
                    ...newPet,
                    'id': id,
                    'uid': uid, // Associate the pet with the current user
                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pet added successfully')),
                    );
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding pet: $error')),
                    );
                  });
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
