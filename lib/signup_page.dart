import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vet_connect/homepage.dart';
import 'package:vet_connect/home_page_for_pets.dart';
import 'auth_services.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final signUpFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;
  bool _passwordVisible = false;
  String? _phoneError;

  final AuthService _authService = AuthService(); // Instance of AuthService

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validation Functions
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    } else if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain alphanumeric characters and underscores';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    } else if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  void _validatePhone() {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _phoneError = 'Please enter your phone number';
      });
    } else {
      setState(() {
        _phoneError = null;
      });
    }
  }

  Future<void> _signUp() async {
    _validatePhone();

    if (signUpFormKey.currentState!.validate() &&
        _phoneError == null &&
        _selectedRole != null) {
      try {
        // Use AuthService to handle signup
        String result = await _authService.signUpUser(
          name: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole!,
        );

        if (result == "User created successfully.") {
          // Navigate to the appropriate home page based on user type
          if (_selectedRole == 'Vet') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (_selectedRole == 'Pet') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePageForPets()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during signup: ${e.toString()}')),
        );
      }
    } else if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role (Vet or Pet)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup Page'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: signUpFormKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create an account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateUsername,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Your Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'US',
                  onChanged: (phone) {
                    _validatePhone();
                  },
                ),
                if (_phoneError != null)
                  Text(_phoneError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Enter Your Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                const Text('Sign up as:'),
                RadioListTile<String>(
                  title: const Text('Vet'),
                  value: 'Vet',
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Pet'),
                  value: 'Pet',
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Sign Up'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
