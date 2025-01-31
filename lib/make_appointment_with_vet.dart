import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_connect/payments_options.dart';

class MakeAppointmentWithVetPage extends StatefulWidget {
  final String vetId;

  const MakeAppointmentWithVetPage({super.key, required this.vetId});

  @override
  _MakeAppointmentWithVetPageState createState() =>
      _MakeAppointmentWithVetPageState();
}

class _MakeAppointmentWithVetPageState
    extends State<MakeAppointmentWithVetPage> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String vetName = '';
  int vetFee = 1000; // Hardcoded fee
  List<TimeOfDay> availableSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchVetDetails();
    _generateTimeSlots();
  }

  Future<void> _fetchVetDetails() async {
    final vetDoc = await FirebaseFirestore.instance
        .collection('vets')
        .doc(widget.vetId)
        .get();
    setState(() {
      vetName = vetDoc['name'];
    });
  }

  void _generateTimeSlots() {
    // Hardcoded time slots with 1-hour intervals, excluding 2:00 PM and 7:00 PM
    availableSlots = [
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 13, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
      const TimeOfDay(hour: 17, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
    ];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _confirmAppointment() async {
    if (selectedTime == null || selectedDate == null) return;

    final selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Save the appointment data in Firestore
    await FirebaseFirestore.instance.collection('appointments').add({
      'vetId': widget.vetId,
      'vetName': vetName,
      'date': selectedDateTime,
      'time': selectedTime!.format(context),
      'fee': vetFee,
    });

    // Navigate to the Payment Options Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentOptionsPage(
          vetName: vetName,
          dateTime: selectedDateTime,
          fee: vetFee,
          vetId: widget.vetId, petOwnerEmail: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Make Appointment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Vet: $vetName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Fee: $vetFee Rs', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectDate,
              child: Text(selectedDate == null
                  ? "Select Date"
                  : selectedDate!.toLocal().toString().split(' ')[0]),
            ),
            const SizedBox(height: 20),
            const Text("Select Time Slot",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: availableSlots.map((slot) {
                final isSelected = selectedTime == slot;
                return ChoiceChip(
                  label: Text(slot.format(context)),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    selectedTime = slot;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _confirmAppointment,
              child: const Text("Confirm Appointment"),
            ),
          ],
        ),
      ),
    );
  }
}
