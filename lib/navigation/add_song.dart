import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSongPage extends StatefulWidget {
  final String? username; // Pass username from login page
  final VoidCallback? onSongAdded; // Callback after saving
  final VoidCallback? onCancel; // Callback on cancel

  const AddSongPage({
    super.key,
    this.username,
    this.onSongAdded,
    this.onCancel,
  });

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final titleController = TextEditingController();
  final artistController = TextEditingController();
  final lyricsController = TextEditingController();
  final youtubeController = TextEditingController();

  final titleFocus = FocusNode();
  final artistFocus = FocusNode();
  final lyricsFocus = FocusNode();
  final youtubeFocus = FocusNode();

  bool isLoading = false;

  Future<void> saveSong() async {
    if (titleController.text.isEmpty ||
        artistController.text.isEmpty ||
        lyricsController.text.isEmpty ||
        youtubeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final createdBy = widget.username ?? user?.email ?? 'Unknown';

      await FirebaseFirestore.instance.collection('songs').add({
        'title': titleController.text,
        'artist': artistController.text,
        'lyrics': lyricsController.text,
        'youtubeUrl': youtubeController.text,
        'createdBy': createdBy,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Switch back to Home tab
      if (widget.onSongAdded != null) widget.onSongAdded!();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add song: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    artistController.dispose();
    lyricsController.dispose();
    youtubeController.dispose();

    titleFocus.dispose();
    artistFocus.dispose();
    lyricsFocus.dispose();
    youtubeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Song')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: titleController,
                focusNode: titleFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(artistFocus),
                decoration: const InputDecoration(labelText: 'Song Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistController,
                focusNode: artistFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(lyricsFocus),
                decoration: const InputDecoration(labelText: 'Artist'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lyricsController,
                focusNode: lyricsFocus,
                maxLines: 5,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(youtubeFocus),
                decoration: const InputDecoration(labelText: 'Lyrics'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: youtubeController,
                focusNode: youtubeFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => saveSong(),
                decoration: const InputDecoration(
                  labelText: 'YouTube Link (Audio Only)',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (widget.onCancel != null) {
                                widget.onCancel!(); // switch to home
                              }
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveSong,
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Song'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
