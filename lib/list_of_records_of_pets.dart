import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_connect/pet_records.dart';

class ListOfRecordsOfPets extends StatelessWidget {
  final String petId;

  const ListOfRecordsOfPets({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List of Medical Records"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medical_records')
            .where('petId', isEqualTo: petId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading records."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No records found."));
          }

          final records = snapshot.data!.docs;
          print(
              "Records retrieved: ${records.length}"); // Debug: check number of records

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index];
              var recordType = record['recordType'];
              var administrationDate = record['administrationDate'] != null
                  ? (record['administrationDate'] as Timestamp).toDate()
                  : null;
              var expirationDate = record['expirationDate'] != null
                  ? (record['expirationDate'] as Timestamp).toDate()
                  : null;
              var notes = record['notes'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    "${index + 1}. $recordType",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (administrationDate != null)
                        Text(
                            "Administered on: ${administrationDate.toLocal()}"),
                      if (expirationDate != null)
                        Text("Expires on: ${expirationDate.toLocal()}"),
                      if (notes.isNotEmpty) Text("Notes: $notes"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Navigate to edit page with record data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetRecordsPage(
                                petId: petId,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecord(context, record.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteRecord(BuildContext context, String recordId) async {
    try {
      await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(recordId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting record: $e')),
      );
    }
  }
}
