import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vet_connect/homepage.dart';
import 'package:vet_connect/home_page_for_pets.dart';
import 'auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vet_model.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'PET_OWNER';
  bool _isLoading = false;

  // Additional controllers for vet registration
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();

  // Additional controllers for pet owner registration
  final _petNameController = TextEditingController();
  final _petTypeController = TextEditingController();
  final _petBreedController = TextEditingController();
  final _petAgeController = TextEditingController();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create user account
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user role
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'role': _selectedRole,
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
        });

        if (_selectedRole == 'VET') {
          // Create vet profile
          final vetModel = VetModel(
            id: userCredential.user!.uid,
            name: _nameController.text.trim(),
            specialization: _specializationController.text.trim(),
            experience: _experienceController.text.trim(),
            location: _locationController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            website: _websiteController.text.trim(),
            openingTime: _openingTimeController.text.trim(),
            closingTime: _closingTimeController.text.trim(),
            about: '',
            imagePath: '',
            isEmergencyAvailable: false,
          );

          await FirebaseFirestore.instance
              .collection('vets')
              .doc(userCredential.user!.uid)
              .set(vetModel.toJson());

          if (!mounted) return;
          // Navigate to vet homepage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => HomePage(currentVet: vetModel)),
          );
        } else {
          // For pet owners, create their initial profile
          await FirebaseFirestore.instance
              .collection('pet_owners')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          // Navigate to pet owner homepage
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePageForPets()),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter your name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter an email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a password' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                      value: 'PET_OWNER', child: Text('Pet Owner')),
                  DropdownMenuItem(value: 'VET', child: Text('Veterinarian')),
                ],
                onChanged: (String? value) {
                  setState(() => _selectedRole = value!);
                },
              ),
              if (_selectedRole == 'VET') ...[
                TextFormField(
                  controller: _specializationController,
                  decoration:
                      const InputDecoration(labelText: 'Specialization'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(labelText: 'Experience'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _websiteController,
                  decoration:
                      const InputDecoration(labelText: 'Website (Optional)'),
                ),
                TextFormField(
                  controller: _openingTimeController,
                  decoration: const InputDecoration(labelText: 'Opening Time'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: _closingTimeController,
                  decoration: const InputDecoration(labelText: 'Closing Time'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
              ],
              if (_selectedRole == 'PET_OWNER') ...[
                TextFormField(
                  controller: _petNameController,
                  decoration: const InputDecoration(labelText: 'Pet Name'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter pet name' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Pet Type'),
                  items: const [
                    DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                    DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                    DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => _petTypeController.text = value ?? '',
                  validator: (value) =>
                      value == null ? 'Please select pet type' : null,
                ),
                TextFormField(
                  controller: _petBreedController,
                  decoration: const InputDecoration(labelText: 'Pet Breed'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter pet breed' : null,
                ),
                TextFormField(
                  controller: _petAgeController,
                  decoration: const InputDecoration(labelText: 'Pet Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter pet age' : null,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _petNameController.dispose();
    _petTypeController.dispose();
    _petBreedController.dispose();
    _petAgeController.dispose();
    super.dispose();
  }
}
