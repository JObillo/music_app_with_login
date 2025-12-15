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
    setState(() => isPlaying = true);
  }

  void togglePlayPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.resume();
    }
    setState(() => isPlaying = !isPlaying);
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
      backgroundColor: const Color(0xFFF7F3F2),
      appBar: AppBar(backgroundColor: const Color(0xFFB76E79)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/${song.imageUrl}',
                width: 170,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholderImage(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB76E79),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              song.artist,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 55,
                color: const Color(0xFFB76E79),
              ),
              onPressed: togglePlayPause,
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: const Color(0xFFB76E79),
                inactiveTrackColor: Colors.grey.shade400,
                thumbColor: const Color(0xFFB76E79),
              ),
              child: Slider(
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
            ),
            Text(
              "${formatTime(current)} / ${formatTime(total)}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.lyrics,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.55,
                    color: Colors.black87,
                  ),
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
      width: 170,
      height: 170,
      color: Colors.grey.shade300,
      child: const Icon(Icons.music_note, size: 50),
    );
  }

  String formatTime(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
