import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
import '../navigation/lyrics_page.dart';
import '../navigation/add_song.dart';

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
  Set<String> favoriteIds = {};
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    setState(() {
      favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> toggleFavorite(Song song) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(song.id);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
      setState(() => favoriteIds.remove(song.id));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      }
    } else {
      await favRef.set(song.toMap());
      setState(() => favoriteIds.add(song.id));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  String maskCreatedBy(String createdBy) {
    if (createdBy.isEmpty) return '****';
    return '${createdBy[0].toUpperCase()}****';
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget bodyContent;

    switch (_selectedIndex) {
      case 0:
        // HOME with search bar
        bodyContent = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title or artist...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase().trim();
                  });
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('songs')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No songs available.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final song = Song.fromDocument(doc);
                    return song.title.toLowerCase().contains(searchQuery) ||
                        song.artist.toLowerCase().contains(searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        'No songs match your search.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final song = Song.fromDocument(filteredDocs[index]);

                      return GestureDetector(
                        onTapDown: (_) => setState(() => pressedIndex = index),
                        onTapCancel: () => setState(() => pressedIndex = null),
                        onTapUp: (_) => setState(() => pressedIndex = null),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LyricsPage(song: song),
                            ),
                          );
                        },
                        child: AnimatedScale(
                          scale: pressedIndex == index ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        song.artist,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'CreatedBy: ${maskCreatedBy(song.createdBy)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey[500],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    favoriteIds.contains(song.id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
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
            ),
          ],
        );
        break;

      case 1:
        // ADD SONG
        bodyContent = AddSongPage(
          username: widget.email ?? widget.username,
          onSongAdded: () => setState(() => _selectedIndex = 0),
        );
        break;

      case 2:
        // FAVORITES
        bodyContent = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('favorites')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text('No favorites.', style: theme.textTheme.bodyMedium),
              );
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final song = Song.fromDocument(docs[index]);
                return ListTile(
                  leading: Image.asset(
                    'assets/images/${song.imageUrl}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LyricsPage(song: song)),
                    );
                  },
                );
              },
            );
          },
        );
        break;

      case 3:
        // PROFILE
        bodyContent = ProfilePage(
          firstname: widget.firstname,
          lastname: widget.lastname,
          username: widget.email ?? widget.username,
        );
        break;

      default:
        bodyContent = const Center(child: Text('Page not found'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Belle Music')),
      body: bodyContent,
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
