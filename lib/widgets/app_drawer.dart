import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String usernameOrEmail;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.usernameOrEmail,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212), // Dark mode background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: const Color(0xFF1F1F1F), // Dark header
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1877F2), // Facebook blue
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white, // Text white
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usernameOrEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          ListTile(
            leading: const Icon(Icons.home, color: Colors.white),
            title: const Text('Home', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
