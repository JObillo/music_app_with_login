import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../models/song.dart';
import 'favorites_page.dart';
import 'lyrics_page.dart';
import 'edit_song_page.dart';
import 'delete_song.dart';

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
  int? pressedIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;

  Set<String> favoriteIds = {};

  void logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  String maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '***@$domain';
    final visible = name.substring(0, 2);
    return '$visible***@$domain';
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _showSearchResults = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> toggleFavorite(Song song) async {
    // Use username as the Firestore user ID
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.username) // <-- username instead of FirebaseAuth
        .collection('favorites')
        .doc(song.id);

    final doc = await favRef.get();
    if (doc.exists) {
      await favRef.delete();
      setState(() {
        favoriteIds.remove(song.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
      }
    } else {
      await favRef.set({
        ...song.toMap(),
        'timestamp': FieldValue.serverTimestamp(), // important for ordering
      });
      setState(() {
        favoriteIds.add(song.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to favorites')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
          username: widget.username, // ✅ pass username
          email:
              widget.email ??
              '', // ✅ pass email (fallback to empty string if null)
          photoUrl: widget.photoUrl,
          onLogout: logout,
          goToFavorites: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesPage(
                  username: widget.username,
                  email: widget.email ?? '',
                  userId: widget.username, // or whatever unique ID you use
                  currentFavorites: favoriteIds,
                  onFavoriteChanged: (updatedFavorites) {
                    setState(() {
                      favoriteIds = updatedFavorites;
                    });
                  },
                ),
              ),
            );
          },
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title or artist',
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _performSearch,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _performSearch(),
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
                    return const Center(child: Text('No songs yet'));
                  }

                  final docs = snapshot.data!.docs;
                  final filteredDocs = _showSearchResults
                      ? docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '')
                              .toString()
                              .toLowerCase();
                          final artist = (data['artist'] ?? '')
                              .toString()
                              .toLowerCase();
                          return title.contains(_searchQuery) ||
                              artist.contains(_searchQuery);
                        }).toList()
                      : docs;

                  if (_showSearchResults && filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('No songs match your search'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final song = Song.fromDocument(doc);

                      return Dismissible(
                        key: Key(song.id),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Edit
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditSongPage(song: song),
                              ),
                            );
                            return false; // Do not dismiss
                          } else {
                            // Delete
                            final result = await showDialog(
                              context: context,
                              builder: (_) => DeleteSongDialog(song: song),
                            );
                            return result == true;
                          }
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LyricsPage(song: song),
                              ),
                            );
                          },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
