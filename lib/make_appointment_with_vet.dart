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
  TimeOfDay? selectedTime;
  String vetName = '';
  double vetFee = 0.0;
  List<TimeOfDay> availableSlots = [];
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
        ),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      selectableDayPredicate: (DateTime date) {
        // Only allow dates on working days
        return workingDays.contains(_getDayName(date));
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _checkBookedSlots();
    }
  }

  Future<void> _checkBookedSlots() async {
    if (selectedDate == null) return;

    final bookedAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vetId', isEqualTo: widget.vetId)
        .where('date',
            isGreaterThanOrEqualTo: DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            ))
        .where('date',
            isLessThan: DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day + 1,
            ))
        .get();

    final bookedTimes = bookedAppointments.docs.map((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      return TimeOfDay(hour: date.hour, minute: date.minute);
    }).toList();

    setState(() {
      availableSlots = availableSlots.where((slot) {
        return !bookedTimes.any((bookedTime) =>
            bookedTime.hour == slot.hour && bookedTime.minute == slot.minute);
      }).toList();
    });
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
      selectedTime!.hour,
      selectedTime!.minute,
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
        title: const Text('Make Appointment'),
      ),
      body: SingleChildScrollView(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${selectedDate!.toString().split(' ')[0]}'),
            ),
            if (selectedDate != null && availableSlots.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Available Time Slots:'),
              Wrap(
                spacing: 8,
                children: availableSlots.map((slot) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() => selectedTime = slot);
                      _confirmAppointment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTime == slot
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    child: Text(slot.format(context)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
