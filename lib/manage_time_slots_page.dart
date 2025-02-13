import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManageTimeSlotsPage extends StatefulWidget {
  final String vetId;
  const ManageTimeSlotsPage({Key? key, required this.vetId}) : super(key: key);

  @override
  State<ManageTimeSlotsPage> createState() => _ManageTimeSlotsPageState();
}

class _ManageTimeSlotsPageState extends State<ManageTimeSlotsPage> {
  Map<String, Map<String, bool>> weeklySlots = {
    'Monday': {},
    'Tuesday': {},
    'Wednesday': {},
    'Thursday': {},
    'Friday': {},
    'Saturday': {},
    'Sunday': {},
  };

  // Add map to track expanded state of each day
  Map<String, bool> expandedStates = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    _loadSavedSlots();
  }

  void _generateTimeSlots() {
    // Generate slots for each day with 30-minute intervals
    for (var day in weeklySlots.keys) {
      final slots = <String, bool>{};
      // Start from 9 AM to 5 PM for better usability
      for (int hour = 9; hour < 17; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final time = DateTime(2024, 1, 1, hour, minute);
          final timeString = DateFormat('HH:mm').format(time);
          slots[timeString] = false;
        }
      }
      weeklySlots[day] = slots;
    }
    // Set initial expanded state for better visibility
    expandedStates['Monday'] = true;
  }

  Future<void> _loadSavedSlots() async {
    try {
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (vetDoc.exists) {
        final data = vetDoc.data() as Map<String, dynamic>;
        if (data['availableSlots'] != null) {
          setState(() {
            for (var day in weeklySlots.keys) {
              if (data['availableSlots'][day] != null) {
                weeklySlots[day] =
                    Map<String, bool>.from(data['availableSlots'][day]);
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading slots: $e');
    }
  }

  Future<void> _saveSlots() async {
    try {
      // Convert weeklySlots to a format suitable for Firestore
      final Map<String, Map<String, bool>> slotsToSave = {};
      for (var entry in weeklySlots.entries) {
        // Only save slots that are marked as available (true)
        slotsToSave[entry.key] = Map.fromEntries(
          entry.value.entries.where((slot) => slot.value),
        );
      }

      // Update only the main vet document
      await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .update({
        'availableSlots': slotsToSave,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Time Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.unfold_more),
            onPressed: () {
              setState(() {
                bool allExpanded = expandedStates.values.every((v) => v);
                for (var day in expandedStates.keys) {
                  expandedStates[day] = !allExpanded;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSlots,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: weeklySlots.length,
        itemBuilder: (context, index) {
          final day = weeklySlots.keys.elementAt(index);
          final slots = weeklySlots[day]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ExpansionTile(
              initiallyExpanded: expandedStates[day] ?? false,
              onExpansionChanged: (expanded) {
                setState(() {
                  expandedStates[day] = expanded;
                });
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(day,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${slots.values.where((v) => v).length} slots selected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available time slots:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                bool allSelected = slots.values.every((v) => v);
                                for (var time in slots.keys) {
                                  weeklySlots[day]![time] = !allSelected;
                                }
                              });
                            },
                            icon: const Icon(Icons.select_all),
                            label: Text(slots.values.every((v) => v)
                                ? 'Deselect All'
                                : 'Select All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (slots.isEmpty)
                        const Text('No time slots available')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: slots.entries.map((entry) {
                            return SizedBox(
                              width: 100,
                              child: FilterChip(
                                label: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: entry.value
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                selected: entry.value,
                                onSelected: (bool selected) {
                                  setState(() {
                                    weeklySlots[day]![entry.key] = selected;
                                  });
                                },
                                selectedColor: Theme.of(context).primaryColor,
                                checkmarkColor: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
