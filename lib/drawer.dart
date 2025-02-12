import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this for Firebase Auth
import 'package:vet_connect/PetListPage.dart';

class MyDrawer extends StatelessWidget {
  final String email; // The user's email
  final String profileImageUrl; // The user's profile image URL
  final Future<void> Function() onLogout; // Changed from Null Function()

  const MyDrawer({
    super.key,
    required this.email,
    required this.profileImageUrl,
    required this.onLogout, // Changed parameter type
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountEmail: Text(email),
            accountName: const Text(
              "Welcome!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            decoration: BoxDecoration(
              color: Colors.deepPurple[500], // Drawer header background color
            ),
          ),
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Pet Profiles'),
            onTap: () {
              // Navigate to pet profiles screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PetListPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout, // Use the passed onLogout function
          ),
        ],
      ),
    );
  }
}
