import 'package:flutter/material.dart';
import '../navigation/lyrics_page.dart';
import '../navigation/song_data.dart';
import '../widgets/nav_bar.dart';
import '../widgets/profile_page.dart';

class HomePage extends StatefulWidget {
  final String firstname;
  final String lastname;
  final String username;
  final String? email;
  final String? photoUrl;

  const HomePage({
    super.key,
    required this.firstname,
    required this.lastname,
    required this.username,
    this.email,
    this.photoUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int? pressedIndex;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    // HOME (Songs)
    if (_selectedIndex == 0) {
      bodyContent = ListView.builder(
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
              scale: pressedIndex == index ? 0.97 : 1,
              duration: const Duration(milliseconds: 120),
              child: Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
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
                            color: Colors.grey.shade300,
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
                                color: Color(0xFFB76E79),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    // PROFILE
    else {
      bodyContent = ProfilePage(
        firstname: widget.firstname,
        lastname: widget.lastname,
        username: widget.email ?? widget.username,
        photoUrl: widget.photoUrl,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belle Music'),
        backgroundColor: const Color(0xFFB76E79),
      ),
      body: bodyContent,
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
