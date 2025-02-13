import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'payments_options.dart';
// ...existing imports...

class MakeAppointmentWithVetPage extends StatefulWidget {
  final String vetId;

  const MakeAppointmentWithVetPage({Key? key, required this.vetId})
      : super(key: key);

  @override
  State<MakeAppointmentWithVetPage> createState() =>
      _MakeAppointmentWithVetPageState();
}

class _MakeAppointmentWithVetPageState
    extends State<MakeAppointmentWithVetPage> {
  // ...existing variables...
  bool is24x7 = false;
  String? startTime;
  String? endTime;
  List<String> workingDays = [];
  int appointmentDuration = 30; // in minutes
  DateTime? selectedDate;
  String? selectedTime;
  String vetName = '';
  double vetFee = 0.0;
  List<String> availableSlots = [];
  String? selectedPetId;
  List<Map<String, dynamic>> userPets = [];

  @override
  void initState() {
    super.initState();
    _fetchVetDetails();
    _fetchUserPets();
  }

  Future<void> _fetchVetDetails() async {
    final vetDoc = await FirebaseFirestore.instance
        .collection('vets')
        .doc(widget.vetId)
        .get();

    final availabilityDoc = await FirebaseFirestore.instance
        .collection('vet_availability')
        .doc(widget.vetId)
        .get();

    if (availabilityDoc.exists) {
      final data = availabilityDoc.data()!;
      setState(() {
        is24x7 = data['is24x7'] ?? false;
        startTime = data['startTime'];
        endTime = data['endTime'];
        workingDays = List<String>.from(data['workingDays'] ?? []);
        appointmentDuration = data['appointmentDuration'] ?? 30;
        vetName = vetDoc['name'];
        _generateTimeSlots();
      });
    }
  }

  Future<void> _fetchUserPets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final petsSnapshot = await FirebaseFirestore.instance
          .collection('pets')
          .where('uid', isEqualTo: userId)
          .get();

      setState(() {
        userPets = petsSnapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList();
      });
    }
  }

  void _generateTimeSlots() {
    availableSlots = [];
    if (!is24x7 && (startTime == null || endTime == null)) return;

    final start = is24x7
        ? const TimeOfDay(hour: 0, minute: 0)
        : _parseTimeString(startTime!);
    final end = is24x7
        ? const TimeOfDay(hour: 23, minute: 59)
        : _parseTimeString(endTime!);

    int currentMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    while (currentMinutes + appointmentDuration <= endMinutes) {
      availableSlots.add(
        TimeOfDay(
          hour: currentMinutes ~/ 60,
          minute: currentMinutes % 60,
        ).format(context),
      );
      currentMinutes += appointmentDuration;
    }
  }

  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Future<void> _loadAvailableSlots(String dayOfWeek) async {
    try {
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (vetDoc.exists && vetDoc.data()!.containsKey('availableSlots')) {
        final slots = vetDoc.data()!['availableSlots'] as Map<String, dynamic>;
        if (slots.containsKey(dayOfWeek)) {
          setState(() {
            availableSlots = List<String>.from(slots[dayOfWeek]);
            availableSlots.sort(); // Sort slots chronologically
          });
        } else {
          setState(() {
            availableSlots = [];
          });
        }
      }
    } catch (e) {
      print('Error loading slots: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });

      // Get day of week and load available slots
      String dayOfWeek = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][picked.weekday - 1];

      await _loadAvailableSlots(dayOfWeek);
    }
  }

  Future<void> _confirmAppointment() async {
    if (selectedTime == null || selectedDate == null || selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet, date and time')),
      );
      return;
    }

    final selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      _parseTimeString(selectedTime!).hour,
      _parseTimeString(selectedTime!).minute,
    );

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to book appointment')),
        );
        return;
      }

      // Create appointment
      await FirebaseFirestore.instance.collection('appointments').add({
        'vetId': widget.vetId,
        'vetName': vetName,
        'petId': selectedPetId,
        'petOwnerId': currentUser.uid,
        'ownerName': currentUser.displayName,
        'appointmentDate': selectedDateTime,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'fee': vetFee,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request sent')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userPets.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Please add a pet first to book an appointment'),
                ),
              )
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Pet'),
                value: selectedPetId,
                items: userPets.map((pet) {
                  return DropdownMenuItem<String>(
                    value: pet['id'] as String,
                    child: Text(pet['petName']?.toString() ?? 'Unnamed Pet'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedPetId = value);
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
            ),
            const SizedBox(height: 20),
            if (selectedDate != null && availableSlots.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Time Slots:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: availableSlots.length,
                        itemBuilder: (context, index) {
                          return ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedTime = availableSlots[index];
                              });
                              // Proceed with booking
                              if (selectedTime != null) {
                                _confirmAppointment();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selectedTime == availableSlots[index]
                                      ? Theme.of(context).primaryColor
                                      : null,
                            ),
                            child: Text(availableSlots[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else if (selectedDate != null)
              const Center(
                child: Text('No available slots for selected date'),
              ),
          ],
        ),
      ),
    );
  }
}
