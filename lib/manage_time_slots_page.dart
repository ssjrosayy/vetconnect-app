import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTimeSlotsPage extends StatefulWidget {
  final String vetId;
  const ManageTimeSlotsPage({Key? key, required this.vetId}) : super(key: key);

  @override
  State<ManageTimeSlotsPage> createState() => _ManageTimeSlotsPageState();
}

class _ManageTimeSlotsPageState extends State<ManageTimeSlotsPage> {
  final Map<String, Map<String, bool>> weeklySlots = {
    'Monday': {},
    'Tuesday': {},
    'Wednesday': {},
    'Thursday': {},
    'Friday': {},
    'Saturday': {},
    'Sunday': {},
  };

  @override
  void initState() {
    super.initState();
    _loadExistingSlots();
    // Initialize time slots for each day
    for (var day in weeklySlots.keys) {
      for (int hour = 9; hour <= 17; hour++) {
        weeklySlots[day]!['$hour:00'] = false;
        weeklySlots[day]!['$hour:30'] = false;
      }
    }
  }

  Future<void> _loadExistingSlots() async {
    final doc = await FirebaseFirestore.instance
        .collection('vets')
        .doc(widget.vetId)
        .collection('slots')
        .doc('weekly_schedule')
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        for (var day in weeklySlots.keys) {
          weeklySlots[day] = Map<String, bool>.from(data[day] ?? {});
        }
      });
    }
  }

  Future<void> _saveSlots() async {
    await FirebaseFirestore.instance
        .collection('vets')
        .doc(widget.vetId)
        .collection('slots')
        .doc('weekly_schedule')
        .set(weeklySlots);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Available Times'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSlots,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: weeklySlots.length,
        itemBuilder: (context, dayIndex) {
          final day = weeklySlots.keys.elementAt(dayIndex);
          final slots = weeklySlots[day]!;

          return ExpansionTile(
            title: Text(day),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.keys.map((timeSlot) {
                  return FilterChip(
                    label: Text(timeSlot),
                    selected: slots[timeSlot] ?? false,
                    onSelected: (bool selected) {
                      setState(() {
                        weeklySlots[day]![timeSlot] = selected;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
