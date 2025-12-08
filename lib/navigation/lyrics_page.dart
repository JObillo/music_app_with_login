import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:audioplayers/audioplayers.dart';

class LyricsPage extends StatefulWidget {
  final Song song;
  const LyricsPage({super.key, required this.song});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  final AudioPlayer player = AudioPlayer();
  Duration current = Duration.zero;
  Duration total = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    player.onDurationChanged.listen((d) {
      setState(() => total = d);
    });

    player.onPositionChanged.listen((p) {
      setState(() => current = p);
    });

    playSong();
  }

  void playSong() async {
    await player.play(AssetSource('songs/${widget.song.audioUrl}'));
    setState(() {
      isPlaying = true;
    });
  }

  void togglePlayPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.resume();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  void dispose() {
    player.stop();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/${song.imageUrl}',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return placeholderImage();
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              song.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(song.artist, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // Play / Pause Button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 50,
              ),
              onPressed: togglePlayPause,
            ),

            // Progress Slider
            Slider(
              min: 0,
              max: total.inSeconds.toDouble(),
              value: current.inSeconds.toDouble().clamp(
                0,
                total.inSeconds.toDouble(),
              ),
              onChanged: (value) {
                player.seek(Duration(seconds: value.toInt()));
              },
            ),
            Text("${formatTime(current)} / ${formatTime(total)}"),
            const SizedBox(height: 20),

            // Lyrics
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.lyrics,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget placeholderImage() {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey,
      child: const Icon(Icons.music_note, color: Colors.white, size: 50),
    );
  }

  String formatTime(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
