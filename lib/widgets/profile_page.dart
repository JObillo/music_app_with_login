import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatelessWidget {
  final String firstname;
  final String lastname;
  final String username; // email
  final String? photoUrl;

  const ProfilePage({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.username,
    this.photoUrl,
  });

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F2),
      body: Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ REAL PROFILE PHOTO
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),

                const SizedBox(height: 20),

                // ✅ REAL NAME
                Text(
                  '$firstname $lastname',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB76E79),
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ REAL EMAIL
                Text(
                  username,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 30),

                Divider(color: Colors.grey.shade300),

                const SizedBox(height: 20),

                // LOGOUT BUTTON (PROFESSIONAL LOOK)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB76E79),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
