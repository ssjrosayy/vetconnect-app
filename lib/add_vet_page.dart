import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'vet_model.dart';

class AddVetPage extends StatefulWidget {
  final Function(VetModel) onSave;
  final VetModel? vet;

  const AddVetPage({super.key, required this.onSave, this.vet});

  @override
  _AddVetPageState createState() => _AddVetPageState();
}

class _AddVetPageState extends State<AddVetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();
  bool _isEmergencyAvailable = false;
  String _imagePath = '';

  File? _selectedImage;
  List<TimeOfDay> selectedSlots = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.vet?.name ?? '';
    _specializationController.text = widget.vet?.specialization ?? '';
    _experienceController.text = widget.vet?.experience ?? '';
    _locationController.text = widget.vet?.location ?? '';
    _aboutController.text = widget.vet?.about ?? '';
    _phoneController.text = widget.vet?.phoneNumber ?? '';
    _emailController.text = widget.vet?.email ?? '';
    _websiteController.text = widget.vet?.website ?? '';
    _openingTimeController.text = widget.vet?.openingTime ?? '';
    _closingTimeController.text = widget.vet?.closingTime ?? '';
    _isEmergencyAvailable = widget.vet?.isEmergencyAvailable ?? false;
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('vet_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveVet() async {
    if (_formKey.currentState!.validate()) {
      try {
        final vetData = VetModel(
          name: _nameController.text,
          specialization: _specializationController.text,
          experience: _experienceController.text,
          location: _locationController.text,
          about: _aboutController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          website: _websiteController.text,
          openingTime: _openingTimeController.text,
          closingTime: _closingTimeController.text,
          imagePath: _imagePath,
          isEmergencyAvailable: _isEmergencyAvailable,
        );

        await FirebaseFirestore.instance
            .collection('vets')
            .add(vetData.toJson());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vet profile added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding vet: $e')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vet == null ? 'Add New Vet' : 'Edit Vet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 200,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutController,
                decoration: const InputDecoration(labelText: 'About'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter about information';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(labelText: 'Specialization'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a specialization';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Experience'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter experience';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a website';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Available Time Slots:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(17, (index) {
                  final hour = 8 + index; // 8 AM to 12 Midnight
                  final timeSlot = TimeOfDay(hour: hour % 24, minute: 0);
                  final isSelected = selectedSlots.contains(timeSlot);

                  return ChoiceChip(
                    label: Text(timeSlot.format(context)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedSlots.add(timeSlot);
                        } else {
                          selectedSlots.remove(timeSlot);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVet,
                child: Text(widget.vet == null ? 'Add Vet' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
