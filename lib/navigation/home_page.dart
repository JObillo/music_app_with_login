import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../navigation/lyrics_page.dart';
import '../navigation/song_data.dart';

class HomePage extends StatefulWidget {
  final String firstname;
  final String lastname;
  final String username;

  const HomePage({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? pressedIndex;

  void logout() {
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
        firstName: widget.firstname,
        lastName: widget.lastname,
        usernameOrEmail: widget.username,
        onLogout: logout,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];

          return GestureDetector(
            onTapDown: (_) => setState(() => pressedIndex = index),
            onTapCancel: () => setState(() => pressedIndex = null),
            onTapUp: (_) => setState(() => pressedIndex = null),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LyricsPage(song: song)),
              );
            },

            child: AnimatedScale(
              scale: pressedIndex == index ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),

              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/${song.imageUrl}',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey,
                          child: const Icon(Icons.music_note),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
//working fine 1