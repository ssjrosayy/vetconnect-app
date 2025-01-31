import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this for Firebase Auth
import 'package:vet_connect/PetListPage.dart';

class MyDrawer extends StatelessWidget {
  final String email; // The user's email
  final String profileImageUrl; // The user's profile image URL

  const MyDrawer({super.key, 
    required this.email,
    required this.profileImageUrl, required Null Function() onLogout,
  });

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Log out from Firebase
    Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login page
  }

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
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
