import 'package:cloud_firestore/cloud_firestore.dart';

class Song {
  final String id; // Firestore document ID
  final String title;
  final String artist;
  final String lyrics;
  final String youtubeUrl;
  final String imageUrl;
  final String createdBy;
  final DateTime timestamp;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.youtubeUrl,
    required this.imageUrl,
    required this.createdBy,
    required this.timestamp,
  });

  factory Song.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Song(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      lyrics: data['lyrics'] ?? '',
      youtubeUrl: data['youtubeUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? 'default.jpg',
      createdBy: data['createdBy'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'lyrics': lyrics,
      'youtubeUrl': youtubeUrl,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'timestamp': timestamp,
    };
  }
}
