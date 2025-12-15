import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSongPage extends StatefulWidget {
  final Song song;

  const EditSongPage({super.key, required this.song});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _lyricsController;
  late TextEditingController _youtubeController;

  final titleFocus = FocusNode();
  final artistFocus = FocusNode();
  final lyricsFocus = FocusNode();
  final youtubeFocus = FocusNode();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _lyricsController = TextEditingController(text: widget.song.lyrics);
    _youtubeController = TextEditingController(text: widget.song.youtubeUrl);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _youtubeController.dispose();

    titleFocus.dispose();
    artistFocus.dispose();
    lyricsFocus.dispose();
    youtubeFocus.dispose();
    super.dispose();
  }

  Future<void> _saveSong() async {
    if (_titleController.text.isEmpty ||
        _artistController.text.isEmpty ||
        _lyricsController.text.isEmpty ||
        _youtubeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('songs')
          .doc(widget.song.id);

      await docRef.update({
        'title': _titleController.text,
        'artist': _artistController.text,
        'lyrics': _lyricsController.text,
        'youtubeUrl': _youtubeController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update song: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Song')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _titleController,
                focusNode: titleFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(artistFocus),
                decoration: const InputDecoration(labelText: 'Song Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _artistController,
                focusNode: artistFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(lyricsFocus),
                decoration: const InputDecoration(labelText: 'Artist'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lyricsController,
                focusNode: lyricsFocus,
                maxLines: 5,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(youtubeFocus),
                decoration: const InputDecoration(labelText: 'Lyrics'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _youtubeController,
                focusNode: youtubeFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveSong(),
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
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveSong,
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
