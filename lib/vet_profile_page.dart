import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'vet_model.dart';
import 'package:intl/intl.dart';

class VetProfilePage extends StatefulWidget {
  final VetModel vet;
  final Function(VetModel) onUpdate;
  final VoidCallback onBookAppointment;

  const VetProfilePage({
    Key? key,
    required this.vet,
    required this.onUpdate,
    required this.onBookAppointment,
  }) : super(key: key);

  @override
  State<VetProfilePage> createState() => _VetProfilePageState();
}

class _VetProfilePageState extends State<VetProfilePage> {
  bool _isEditing = false;
  bool _isCurrentVet = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  File? _imageFile;
  bool _isEmergencyAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkCurrentVet();
  }

  Future<void> _checkCurrentVet() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        _isCurrentVet = currentUser.uid == widget.vet.id &&
            userDoc.data()?['role'] == 'VET';
      });
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.vet.name);
    _specializationController =
        TextEditingController(text: widget.vet.specialization);
    _experienceController = TextEditingController(text: widget.vet.experience);
    _locationController = TextEditingController(text: widget.vet.location);
    _aboutController = TextEditingController(text: widget.vet.about);
    _phoneController = TextEditingController(text: widget.vet.phoneNumber);
    _emailController = TextEditingController(text: widget.vet.email);
    _websiteController = TextEditingController(text: widget.vet.website);
    _isEmergencyAvailable = widget.vet.isEmergencyAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Profile'),
        actions: [
          if (_isCurrentVet) // Only show edit button if current user is the vet
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(height: 16),
              _buildProfileFields(),
              if (!_isCurrentVet) // Show book appointment button only for pet owners
                Center(
                  child: ElevatedButton(
                    onPressed: () => _showAppointmentBookingDialog(context),
                    child: const Text('Book Appointment'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : (widget.vet.imagePath.isNotEmpty
                    ? NetworkImage(widget.vet.imagePath) as ImageProvider
                    : const AssetImage('assets/default_profile.png')),
          ),
          if (_isEditing && _isCurrentVet)
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileFields() {
    return Column(
      children: [
        _buildTextField(_nameController, 'Name', enabled: _isEditing),
        _buildTextField(_specializationController, 'Specialization',
            enabled: _isEditing),
        _buildTextField(_experienceController, 'Experience',
            enabled: _isEditing),
        _buildTextField(_locationController, 'Location', enabled: _isEditing),
        _buildTextField(_aboutController, 'About',
            enabled: _isEditing, maxLines: 3),
        _buildTextField(_phoneController, 'Phone Number', enabled: _isEditing),
        _buildTextField(_emailController, 'Email', enabled: _isEditing),
        _buildTextField(_websiteController, 'Website', enabled: _isEditing),
        if (_isEditing && _isCurrentVet)
          SwitchListTile(
            title: const Text('Emergency Available'),
            value: _isEmergencyAvailable,
            onChanged: (value) => setState(() => _isEmergencyAvailable = value),
          ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool enabled = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String imageUrl = widget.vet.imagePath;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vet_profiles')
            .child('${widget.vet.id}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedVet = VetModel(
        id: widget.vet.id,
        name: _nameController.text,
        specialization: _specializationController.text,
        experience: _experienceController.text,
        location: _locationController.text,
        about: _aboutController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text,
        website: _websiteController.text,
        imagePath: imageUrl,
        openingTime: widget.vet.openingTime,
        closingTime: widget.vet.closingTime,
        isEmergencyAvailable: _isEmergencyAvailable,
      );

      await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vet.id)
          .update(updatedVet.toMap());

      widget.onUpdate(updatedVet);
      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _showAppointmentBookingDialog(BuildContext context) async {
    DateTime? selectedDate;
    String? selectedTimeSlot;
    final availableSlots = widget.vet.availableSlots ?? {};

    selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      // Get the day of the week
      final dayOfWeek = DateFormat('EEEE').format(selectedDate);

      // Get available time slots for that day
      final daySlots = availableSlots[dayOfWeek] ?? {};

      if (daySlots.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available slots for this day')),
        );
        return;
      }

      // Check for existing bookings on the selected date
      final existingBookings = await FirebaseFirestore.instance
          .collection('appointments')
          .where('vetId', isEqualTo: widget.vet.id)
          .where('date',
              isGreaterThanOrEqualTo: DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day))
          .where('date',
              isLessThan: DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day + 1))
          .get();

      // Create a set of booked time slots
      final bookedSlots = existingBookings.docs
          .map((doc) => DateFormat('HH:mm')
              .format((doc.data() as Map<String, dynamic>)['date'].toDate()))
          .toSet();

      // Filter out booked slots
      final availableTimeSlots = daySlots.keys
          .where((slot) => !bookedSlots.contains(slot))
          .toList()
        ..sort();

      if (availableTimeSlots.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All slots are booked for this day')),
        );
        return;
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
                'Select Time Slot for ${DateFormat('EEEE, MMMM d').format(selectedDate!)}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableTimeSlots.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(availableTimeSlots[index]),
                    onTap: () {
                      selectedTimeSlot = availableTimeSlots[index];
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedTimeSlot != null) {
        // Parse the selected time
        final timeComponents = selectedTimeSlot!.split(':');
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          int.parse(timeComponents[0]),
          int.parse(timeComponents[1]),
        );

        try {
          // Create the appointment
          await FirebaseFirestore.instance.collection('appointments').add({
            'vetId': widget.vet.id,
            'petOwnerId': FirebaseAuth.instance.currentUser?.uid,
            'date': selectedDateTime,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'timeSlot': selectedTimeSlot,
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment request sent')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error booking appointment: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}
