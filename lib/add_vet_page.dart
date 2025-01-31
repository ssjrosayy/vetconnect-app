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
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _openingTimeController;
  late TextEditingController _closingTimeController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _feeController;
  File? _selectedImage;
  bool _isEmergencyAvailable = false;
  List<TimeOfDay> selectedSlots = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vet?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.vet?.description ?? '');
    _addressController = TextEditingController(text: widget.vet?.address ?? '');
    _openingTimeController =
        TextEditingController(text: widget.vet?.openingTime ?? '');
    _closingTimeController =
        TextEditingController(text: widget.vet?.closingTime ?? '');
    _websiteController = TextEditingController(text: widget.vet?.website ?? '');
    _phoneController = TextEditingController(text: widget.vet?.phone ?? '');
    _emailController = TextEditingController(text: widget.vet?.email ?? '');
    _feeController = TextEditingController(); // New fee controller
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

  Future<void> _saveToFirestore(VetModel vet) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final imageUrl =
          _selectedImage != null ? await _uploadImage(_selectedImage!) : null;

      final vetData = vet.toJson();
      if (imageUrl != null) vetData['imageUrl'] = imageUrl;
      vetData['fee'] = int.tryParse(_feeController.text) ?? 0; // Save fee
      vetData['availableSlots'] = selectedSlots
          .map((slot) => slot.format(context))
          .toList(); // Save selected slots

      await firestore.collection('vets').add(vetData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vet saved successfully!')),
      );
    } catch (e) {
      print('Error saving vet: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save vet. Please try again.')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newVet = VetModel(
        id: '', // Firestore will generate an ID
        name: _nameController.text,
        description: _descriptionController.text,
        address: _addressController.text,
        openingTime: _openingTimeController.text,
        closingTime: _closingTimeController.text,
        website: _websiteController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        isEmergencyAvailable: _isEmergencyAvailable,
        imagePath: '',
      );

      _saveToFirestore(newVet);
      widget.onSave(newVet);
      Navigator.pop(context);
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
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
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
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _websiteController, // Website field
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a website';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController, // Phone number field
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController, // Email field
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _feeController, // New fee field
                decoration: const InputDecoration(labelText: 'Fee'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Available Time Slots:',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                onPressed: _submitForm,
                child: Text(widget.vet == null ? 'Add Vet' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
