import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vet_model.dart';

class EditVetProfilePage extends StatefulWidget {
  final VetModel currentVet;

  const EditVetProfilePage({Key? key, required this.currentVet})
      : super(key: key);

  @override
  State<EditVetProfilePage> createState() => _EditVetProfilePageState();
}

class _EditVetProfilePageState extends State<EditVetProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  bool _isEmergencyAvailable = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentVet.name);
    _specializationController =
        TextEditingController(text: widget.currentVet.specialization);
    _experienceController =
        TextEditingController(text: widget.currentVet.experience);
    _locationController =
        TextEditingController(text: widget.currentVet.location);
    _aboutController = TextEditingController(text: widget.currentVet.about);
    _phoneController =
        TextEditingController(text: widget.currentVet.phoneNumber);
    _emailController = TextEditingController(text: widget.currentVet.email);
    _websiteController = TextEditingController(text: widget.currentVet.website);
    _isEmergencyAvailable = widget.currentVet.isEmergencyAvailable;
  }

  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.currentVet.id)
          .update({
        'name': _nameController.text,
        'specialization': _specializationController.text,
        'experience': _experienceController.text,
        'location': _locationController.text,
        'about': _aboutController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'website': _websiteController.text,
        'isEmergencyAvailable': _isEmergencyAvailable,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(labelText: 'Specialization'),
            ),
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(labelText: 'Experience'),
            ),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextFormField(
              controller: _aboutController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'About'),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
            ),
            SwitchListTile(
              title: const Text('Emergency Available'),
              value: _isEmergencyAvailable,
              onChanged: (bool value) {
                setState(() {
                  _isEmergencyAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
    );
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
