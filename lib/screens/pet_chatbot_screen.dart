import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chatgpt_service.dart';
import '../config/api_keys.dart';

class PetChatbotScreen extends StatefulWidget {
  const PetChatbotScreen({super.key});

  @override
  State<PetChatbotScreen> createState() => _PetChatbotScreenState();
}

class _PetChatbotScreenState extends State<PetChatbotScreen> {
  // Constants
  static const String _collectionPath = 'pet_chatbot_messages';

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final ChatGPTService _chatService;

  // State
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Check authentication state when screen loads
    final user = _auth.currentUser;
    debugPrint('Current user on init: ${user?.uid ?? 'No user found'}');
    debugPrint('User email: ${user?.email ?? 'No email'}');
    debugPrint('User is authenticated: ${user != null}');
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _chatService = ChatGPTService(APIKeys.openAIKey);
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize chat service';
          _isInitialized = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    if (!_isInitialized) {
      _showError('Chat service is not initialized');
      return;
    }

    final user = _auth.currentUser;
    // Add detailed auth debugging
    debugPrint('Attempting to send message...');
    debugPrint('Current user: ${user?.uid ?? 'No user found'}');
    debugPrint('User email: ${user?.email ?? 'No email'}');
    debugPrint('Is user authenticated: ${user != null}');

    if (user == null) {
      _showError('Please sign in to continue');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Send user message
      await _saveMessage(trimmedMessage, user.uid, true);
      _messageController.clear();

      // Get and send AI response
      final response = await _chatService.getPetCareResponse(trimmedMessage);
      await _saveMessage(response, user.uid, false);

      // Auto-scroll to bottom
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error in message flow: $e');
      _showError('Failed to send message');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveMessage(
      String content, String userId, bool isUserMessage) async {
    try {
      debugPrint('Saving message to Firestore...');
      debugPrint('Collection: $_collectionPath');
      debugPrint('UserId: $userId');

      final messageData = {
        'content': content,
        'userId': userId,
        'isUserMessage': isUserMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      debugPrint('Message data: $messageData');

      await _firestore.collection(_collectionPath).add(messageData);
      debugPrint('Message saved successfully');
    } catch (e) {
      debugPrint('Error saving message: $e');
      throw Exception('Failed to save message');
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to use the chat assistant'),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Care Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final user = _auth.currentUser;
    debugPrint('Building message list for user: ${user?.uid}');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: user?.uid)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('StreamBuilder error: ${snapshot.error}');
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start a conversation!'),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
        );
      },
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isUserMessage = data['isUserMessage'] as bool? ?? false;
    final content = data['content'] as String? ?? 'Error: Empty message';

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isUserMessage ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUserMessage ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                enabled: !_isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: _isLoading ? null : _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              onPressed: _isLoading
                  ? null
                  : () => _sendMessage(_messageController.text),
            ),
          ],
        ),
      ),
    );
  }
}
