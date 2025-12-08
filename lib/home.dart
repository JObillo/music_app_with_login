import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late User? user;
  String firstName = '';
  String lastName = '';
  String usernameOrEmail = '';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    // Get full name from displayName
    final fullName = user?.displayName ?? 'No Name';
    if (fullName.contains(' ')) {
      final parts = fullName.split(' ');
      firstName = parts[0];
      lastName = parts.sublist(1).join(' ');
    } else {
      firstName = fullName;
      lastName = '';
    }

    // Extract username or use actual email
    final email = user?.email ?? '';
    if (email.endsWith('@example.com')) {
      // If fake email (from username), remove the domain
      usernameOrEmail = email.split('@')[0];
    } else {
      // Use actual email
      usernameOrEmail = email;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return; // ✅ check if widget is still in tree
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, $firstName $lastName!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              usernameOrEmail.contains('@')
                  ? 'Email: $usernameOrEmail'
                  : 'Username: $usernameOrEmail',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
