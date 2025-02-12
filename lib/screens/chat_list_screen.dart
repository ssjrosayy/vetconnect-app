import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String currentUserId;
  final bool isVet;
  final String currentUserName;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
    required this.isVet,
    required this.currentUserName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // First get appointments to find connected vets/pet owners
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where(isVet ? 'vetId' : 'petOwnerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, appointmentSnapshot) {
          if (appointmentSnapshot.hasError) {
            return Center(child: Text('Error: ${appointmentSnapshot.error}'));
          }

          if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = appointmentSnapshot.data?.docs ?? [];

          if (appointments.isEmpty) {
            return const Center(
              child: Text(
                  'No appointments found. Book an appointment to start chatting.'),
            );
          }

          // Get unique IDs of connected users
          final Set<String> connectedUserIds = appointments.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return isVet
                ? data['petOwnerId'] as String
                : data['vetId'] as String;
          }).toSet();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where(isVet ? 'vetId' : 'petOwnerId', isEqualTo: currentUserId)
                .where(isVet ? 'petOwnerId' : 'vetId',
                    whereIn: connectedUserIds.toList())
                .snapshots(),
            builder: (context, chatSnapshot) {
              if (chatSnapshot.hasError) {
                return Center(child: Text('Error: ${chatSnapshot.error}'));
              }

              if (chatSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final chats = chatSnapshot.data?.docs ?? [];

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatData = chats[index].data() as Map<String, dynamic>;
                  final otherUserId =
                      isVet ? chatData['petOwnerId'] : chatData['vetId'];
                  final otherUserName =
                      isVet ? chatData['petOwnerName'] : chatData['vetName'];

                  // Find related appointment
                  final relatedAppointment = appointments.firstWhere(
                    (appointment) {
                      final appData =
                          appointment.data() as Map<String, dynamic>;
                      return isVet
                          ? appData['petOwnerId'] == otherUserId
                          : appData['vetId'] == otherUserId;
                    },
                  );
                  final appointmentData =
                      relatedAppointment.data() as Map<String, dynamic>;
                  final appointmentDate =
                      (appointmentData['date'] as Timestamp).toDate();

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(otherUserName ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chatData['lastMessage'] ?? 'No messages'),
                        Text(
                          'Appointment: ${appointmentDate.toString().split(' ')[0]}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chats[index].id,
                            senderId: currentUserId,
                            receiverId: isVet
                                ? chatData['petOwnerId']
                                : chatData['vetId'],
                            senderName: currentUserName,
                            receiverName: isVet
                                ? chatData['petOwnerName']
                                : chatData['vetName'],
                          ),
                        ),
                      );
                    },
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
