import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import '../navigation/lyrics_page.dart';
import '../navigation/song_data.dart'; // contains 'songs' list

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

    final fullName = user?.displayName ?? 'No Name';
    if (fullName.contains(' ')) {
      final parts = fullName.split(' ');
      firstName = parts[0];
      lastName = parts.sublist(1).join(' ');
    } else {
      firstName = fullName;
      lastName = '';
    }

    final email = user?.email ?? '';
    if (email.endsWith('@example.com')) {
      usernameOrEmail = email.split('@')[0];
    } else {
      usernameOrEmail = email;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(
        firstName: firstName,
        lastName: lastName,
        usernameOrEmail: usernameOrEmail,
        onLogout: logout,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LyricsPage(song: song)),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/${song.imageUrl}',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
