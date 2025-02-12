import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';  // Add this line
import 'package:vet_connect/payments_options.dart';
import 'screens/chat_screen.dart';
import 'services/notification_service.dart';

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
  String appointmentId = '';

  @override
  void initState() {
    super.initState();
    _fetchVetDetails();
    _generateTimeSlots();
  }

  Future<void> _fetchVetDetails() async {
    try {
      final vetDoc = await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .get();

      if (!vetDoc.exists) {
        throw Exception('Vet not found');
      }

      setState(() {
        vetName = vetDoc.data()?['name'] ?? 'Unknown Vet';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching vet details: $e')),
      );
    }
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
    if (selectedTime == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    try {
      final selectedDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Check if the selected time is in the past
      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot book appointment in the past')),
        );
        return;
      }

      // Save the appointment data in Firestore
      final appointmentRef =
          await FirebaseFirestore.instance.collection('appointments').add({
        'vetId': widget.vetId,
        'vetName': vetName,
        'date': selectedDateTime,
        'time': selectedTime!.format(context),
        'fee': vetFee,
        'status': 'scheduled',
        'createdAt': DateTime.now(),
      });

      appointmentId = appointmentRef.id;

      // Schedule reminder notification
      await NotificationService.scheduleAppointmentReminder(
        appointmentRef.id.hashCode,
        'Appointment Reminder',
        'You have an appointment with Dr. $vetName in 1 hour',
        selectedDateTime,
      );

      // Navigate to the Payment Options Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentOptionsPage(
            vetName: vetName,
            dateTime: selectedDateTime,
            fee: vetFee,
            vetId: widget.vetId,
            petOwnerEmail: '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating appointment: $e')),
      );
    }
  }

  Future<void> _cancelAppointment() async {
    if (appointmentId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': 'cancelled'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment cancelled successfully')),
    );

    Navigator.pop(context);
  }

  Future<void> _showTimeSlots(BuildContext context, DateTime selectedDate) async {
    final doc = await FirebaseFirestore.instance
        .collection('vets')
        .doc(widget.vetId)
        .collection('slots')
        .doc('weekly_schedule')
        .get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available slots found')),
      );
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final daySlots = Map<String, bool>.from(
      data[DateFormat('EEEE').format(selectedDate)] ?? {},
    );

    // Check which slots are already booked
    final bookedSlots = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vetId', isEqualTo: widget.vetId)
        .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
        .get();

    for (var doc in bookedSlots.docs) {
      final appointmentData = doc.data();
      daySlots[appointmentData['slot']] = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Available Slots for ${DateFormat('EEEE, MMM d').format(selectedDate)}'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daySlots.entries.map((entry) {
              return FilterChip(
                label: Text(entry.key),
                selected: entry.value,
                onSelected: entry.value
                    ? (bool selected) async {
                        Navigator.pop(context);
                        // Book the appointment
                        await _bookAppointment(selectedDate, entry.key);
                      }
                    : null,
                backgroundColor: entry.value ? null : Colors.grey,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _bookAppointment(DateTime date, String slot) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book an appointment')),
      );
      return;
    }

    try {
      // Create appointment document
      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'vetId': widget.vetId,
        'vetName': vetName,
        'petOwnerId': currentUser.uid,
        'petOwnerName': currentUser.displayName ?? 'Pet Owner',
        'date': date,
        'slot': slot,
        'fee': vetFee,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      appointmentId = appointmentRef.id;

      // Schedule notification
      await NotificationService.scheduleAppointmentReminder(
        appointmentRef.id.hashCode,
        'Appointment Reminder',
        'You have an appointment with Dr. $vetName in 1 hour',
        date,
      );

      // Navigate to payment options
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentOptionsPage(
            vetName: vetName,
            dateTime: date,
            fee: vetFee,
            vetId: widget.vetId,
            petOwnerEmail: currentUser.email ?? '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Make Appointment"),
        actions: [
          if (appointmentId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelAppointment,
              tooltip: 'Cancel Appointment',
            ),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('appointments')
                .where('vetId', isEqualTo: widget.vetId)
                .where('status', isEqualTo: 'completed')
                .limit(1)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.chat),
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;

                    // Get vet details
                    final vetDoc = await FirebaseFirestore.instance
                        .collection('vets')
                        .doc(widget.vetId)
                        .get();

                    final vetData = vetDoc.data() as Map<String, dynamic>;
                    final vetName = vetData['name'] as String;

                    // Create or get existing chat document
                    final chatDoc = await FirebaseFirestore.instance
                        .collection('chats')
                        .where('vetId', isEqualTo: widget.vetId)
                        .where('petOwnerId', isEqualTo: currentUser.uid)
                        .get();

                    String chatId;
                    if (chatDoc.docs.isEmpty) {
                      // Create new chat
                      final newChatRef = await FirebaseFirestore.instance
                          .collection('chats')
                          .add({
                        'vetId': widget.vetId,
                        'petOwnerId': currentUser.uid,
                        'vetName': vetName,
                        'petOwnerName': currentUser.displayName ?? 'Pet Owner',
                        'createdAt': FieldValue.serverTimestamp(),
                        'lastMessage': '',
                        'lastMessageTime': FieldValue.serverTimestamp(),
                      });
                      chatId = newChatRef.id;
                    } else {
                      chatId = chatDoc.docs.first.id;
                    }

                    if (!mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
                          senderId: currentUser.uid,
                          receiverId: widget.vetId,
                          senderName: currentUser.displayName ?? 'Pet Owner',
                          receiverName: vetName,
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Vet: $vetName',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
