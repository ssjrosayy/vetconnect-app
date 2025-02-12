import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/chat_screen.dart';

class SelectVetToChatPage extends StatefulWidget {
  const SelectVetToChatPage({super.key});

  @override
  State<SelectVetToChatPage> createState() => _SelectVetToChatPageState();
}

class _SelectVetToChatPageState extends State<SelectVetToChatPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Vet to Chat"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('petOwnerId', isEqualTo: currentUser?.uid)
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
              final vetData = vets[index].data() as Map<String, dynamic>;
              final vetName = vetData['vetName'] as String;
              final vetId = vetData['vetId'] as String;

              return ListTile(
                title: Text(vetName),
                onTap: () async {
                  // Create or get existing chat document
                  final chatDoc = await FirebaseFirestore.instance
                      .collection('chats')
                      .where('vetId', isEqualTo: vetId)
                      .where('petOwnerId', isEqualTo: currentUser?.uid)
                      .get();

                  String chatId;
                  if (chatDoc.docs.isEmpty) {
                    final newChatRef = await FirebaseFirestore.instance
                        .collection('chats')
                        .add({
                      'vetId': vetId,
                      'petOwnerId': currentUser?.uid,
                      'vetName': vetName,
                      'petOwnerName': currentUser?.displayName ?? 'Pet Owner',
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                    });
                    chatId = newChatRef.id;
                  } else {
                    chatId = chatDoc.docs.first.id;
                  }

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        senderId: currentUser?.uid ?? '',
                        receiverId: vetId,
                        senderName: currentUser?.displayName ?? 'Pet Owner',
                        receiverName: vetName,
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
