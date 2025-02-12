import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final recorder = AudioRecorder(); // Use this instead
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _currentRecordingPath;

  @override
  void initState() {
    super.initState();
    // Initialize the recorder
    recorder.hasPermission().then((hasPermission) {
      if (!hasPermission) {
        // Handle permission not granted
      }
    });
  }

  @override
  void dispose() {
    recorder.dispose(); // Clean up the recorder
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String type, {String? content, File? file}) async {
    if ((type == 'text' && content!.trim().isEmpty) ||
        (type != 'text' && file == null)) return;

    String? mediaUrl;
    if (file != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child('${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(file);
      mediaUrl = await ref.getDownloadURL();
    }

    // Create message in subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'senderId': widget.senderId, // Use senderId from widget
      'receiverId': widget.receiverId,
      'senderName': widget.senderName,
      'type': type,
      'content': type == 'text' ? content : mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .set({
      'lastMessage': type == 'text' ? content : '${type} message',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': widget.senderId,
    }, SetOptions(merge: true));

    if (type == 'text') _messageController.clear();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _sendMessage('image', file: File(image.path));
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      final dir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await recorder.start(const RecordConfig(),
          path:
              _currentRecordingPath!); // Use recorder instead of _audioRecorder
      setState(() => _isRecording = true);
    } else {
      await recorder.stop(); // Use recorder instead of _audioRecorder
      setState(() => _isRecording = false);

      if (_currentRecordingPath != null) {
        await _sendMessage('audio', file: File(_currentRecordingPath!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Chat with ${widget.receiverName}')), // Use receiverName
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final isMe = message['senderId'] == widget.senderId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: _buildMessageContent(message),
      ),
    );
  }

  Widget _buildMessageContent(DocumentSnapshot message) {
    switch (message['type']) {
      case 'text':
        return Text(message['content']);
      case 'image':
        return GestureDetector(
          onTap: () => _showFullImage(message['content']),
          child: Image.network(
            message['content'],
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        );
      case 'audio':
        return _buildAudioPlayer(message['content']);
      default:
        return const Text('Unsupported message type');
    }
  }

  Widget _buildAudioPlayer(String url) {
    return IconButton(
      icon: const Icon(Icons.play_arrow),
      onPressed: () => _audioPlayer.play(UrlSource(url)),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(url),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _toggleRecording,
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () =>
                  _sendMessage('text', content: _messageController.text),
            ),
          ],
        ),
      ),
    );
  }
}
