import 'package:flutter/material.dart';
import 'selectvettochat.dart';

class OnlineConsultationPage extends StatelessWidget {
  const OnlineConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Online Consultation"),
      ),
      body: const Center(
        child: Text("Consult with your selected vets online"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectVetToChatPage()),
          );
        },
        tooltip: 'New Chat',
        child: const Icon(Icons.chat),
      ),
    );
  }
}
