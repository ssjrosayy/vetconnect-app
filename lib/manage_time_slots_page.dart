import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTimeSlotsPage extends StatefulWidget {
  final String vetId;
  const ManageTimeSlotsPage({Key? key, required this.vetId}) : super(key: key);

  @override
  State<ManageTimeSlotsPage> createState() => _ManageTimeSlotsPageState();
}

class _ManageTimeSlotsPageState extends State<ManageTimeSlotsPage> {
  // Map to store selected time slots for each day
  Map<String, Set<String>> selectedSlots = {
    'Monday': {},
    'Tuesday': {},
    'Wednesday': {},
    'Thursday': {},
    'Friday': {},
    'Saturday': {},
    'Sunday': {},
  };

  // Generate time slots for 24 hours with 30-minute intervals
  List<String> generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        String hourStr = hour.toString().padLeft(2, '0');
        String minuteStr = minute.toString().padLeft(2, '0');
        slots.add('$hourStr:$minuteStr');
      }
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingSlots();
  }

  Future<void> _loadExistingSlots() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (doc.exists && doc.data()!.containsKey('availableSlots')) {
        final slots = doc.data()!['availableSlots'] as Map<String, dynamic>;
        setState(() {
          selectedSlots = slots.map((key, value) =>
              MapEntry(key, Set<String>.from(value as List<dynamic>)));
        });
      }
    } catch (e) {
      print('Error loading slots: $e');
    }
  }

  Future<void> _saveSlots() async {
    try {
      await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .update({
        'availableSlots':
            selectedSlots.map((key, value) => MapEntry(key, value.toList())),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time slots saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving time slots: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = generateTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Time Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSlots,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Monday'),
                Tab(text: 'Tuesday'),
                Tab(text: 'Wednesday'),
                Tab(text: 'Thursday'),
                Tab(text: 'Friday'),
                Tab(text: 'Saturday'),
                Tab(text: 'Sunday'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ].map((day) => _buildDaySlots(day, timeSlots)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySlots(String day, List<String> timeSlots) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: timeSlots.map((slot) {
          final isSelected = selectedSlots[day]?.contains(slot) ?? false;
          return FilterChip(
            label: Text(slot),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  selectedSlots[day]?.add(slot);
                } else {
                  selectedSlots[day]?.remove(slot);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
