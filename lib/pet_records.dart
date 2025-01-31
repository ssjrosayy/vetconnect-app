import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vet_connect/list_of_records_of_pets.dart';

class PetRecordsPage extends StatefulWidget {
  final String petId;

  const PetRecordsPage({super.key, required this.petId});

  @override
  _PetRecordsPageState createState() => _PetRecordsPageState();
}

class _PetRecordsPageState extends State<PetRecordsPage> {
  final _formKey = GlobalKey<FormState>();
  String _recordType = 'Vaccination';
  DateTime _administrationDate = DateTime.now();
  DateTime _expirationDate = DateTime.now();
  String _notes = '';
  File? _photoFile;
  File? _documentFile;
  bool isEditing = false;
  String? editingRecordId; // ID of the record being edited

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add or Edit Record"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _recordType,
                items: ['Vaccination', 'Deworming', 'Flees and Ticks', 'Other']
                    .map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _recordType = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Record type",
                ),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Administration date",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _administrationDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  setState(() {
                    _administrationDate = pickedDate!;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Expiration date",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  setState(() {
                    _expirationDate = pickedDate!;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Notes",
                ),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _notes = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isEditing ? _updateRecord : _saveRecord,
                child: Text(isEditing ? "Update Record" : "Add Record"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ListOfRecordsOfPets(petId: widget.petId),
                    ),
                  );
                },
                child: const Text("View All Records"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Save a new record to Firestore
  void _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('medical_records').add({
        'petId': widget.petId,
        'recordType': _recordType,
        'administrationDate': _administrationDate,
        'expirationDate': _expirationDate,
        'notes': _notes,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _clearForm();
    }
  }

  // Update an existing record in Firestore
  void _updateRecord() async {
    if (editingRecordId != null && _formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(editingRecordId)
          .update({
        'recordType': _recordType,
        'administrationDate': _administrationDate,
        'expirationDate': _expirationDate,
        'notes': _notes,
      });
      setState(() {
        isEditing = false;
        editingRecordId = null;
      });
      _clearForm();
    }
  }

  // Clear the form fields
  void _clearForm() {
    setState(() {
      _recordType = 'Vaccination';
      _administrationDate = DateTime.now();
      _expirationDate = DateTime.now();
      _notes = '';
    });
  }
}
