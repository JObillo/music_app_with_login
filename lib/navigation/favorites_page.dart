import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lyrics_page.dart';

class FavoritesPage extends StatefulWidget {
  final String username;
  final String? email;
  final Set<String> currentFavorites;
  final Function(Set<String>)? onFavoriteChanged;

  const FavoritesPage({
    super.key,
    required this.username,
    this.email,
    required this.currentFavorites,
    this.onFavoriteChanged,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> favoriteIds = {};
  int? pressedIndex;

  @override
  void initState() {
    super.initState();
    favoriteIds = Set<String>.from(widget.currentFavorites);
  }

  Future<void> toggleFavorite(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(song.id); // Use ID

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
      setState(() {
        favoriteIds.remove(song.id);
      });
      widget.onFavoriteChanged?.call(favoriteIds);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      }
    } else {
      await favRef.set(song.toMap());
      setState(() {
        favoriteIds.add(song.id);
      });
      widget.onFavoriteChanged?.call(favoriteIds);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorite songs'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final song = Song.fromDocument(doc); // Convert using fromDocument

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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            favoriteIds.contains(song.id)
                                ? Icons.thumb_up
                                : Icons.thumb_up_off_alt,
                            color: Colors.blue,
                          ),
                          onPressed: () => toggleFavorite(song),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
