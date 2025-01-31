import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatscreen.dart';

class SelectVetToChatPage extends StatelessWidget {
  const SelectVetToChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Vet to Chat"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: 'currentUserId') // Replace with actual user ID
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No appointments found with vets"));
          }

          final vets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              final vetData = vets[index];
              final vetName = vetData['vetName'];
              final vetId = vetData['vetId'];

              return ListTile(
                title: Text(vetName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        vetId: vetId,
                        vetName: vetName,
                      ),
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
