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
  String username = '';

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

    // Extract username from email (before @)
    final email = user?.email ?? '';
    if (email.contains('@')) {
      username = email.split('@')[0];
    } else {
      username = email;
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
            Text('Username: $username', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
