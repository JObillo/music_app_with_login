import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteSongDialog extends StatelessWidget {
  final Song song;

  const DeleteSongDialog({super.key, required this.song});

  Future<void> _deleteSong(BuildContext context) async {
    final docRef = FirebaseFirestore.instance.collection('songs').doc(song.id);
    await docRef.delete();
    if (context.mounted) {
      Navigator.pop(context, true); // Return true for confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Song deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Song'),
      content: Text('Are you sure you want to delete "${song.title}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => _deleteSong(context),
          child: const Text('Yes', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
