import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current logged-in user
    final User? user = FirebaseAuth.instance.currentUser;

    final String email = user?.email ?? 'No Email';
    final String fullName = user?.displayName ?? 'No Name';

    // Optional: split fullName into first and last
    String firstName = '';
    String lastName = '';
    if (fullName.contains(' ')) {
      final parts = fullName.split(' ');
      firstName = parts[0];
      lastName = parts.sublist(1).join(' ');
    } else {
      firstName = fullName;
      lastName = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $firstName $lastName!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10),
            Text('Email: $email', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
