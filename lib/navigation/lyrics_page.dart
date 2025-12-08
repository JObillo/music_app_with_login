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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Smaller image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/${song.imageUrl}',
                width: 170, // reduced
                height: 170, // reduced
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholderImage(),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              song.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            Text(
              song.artist,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

            const SizedBox(height: 5),

            // Play/Pause Button
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 55,
                color: Color(0xFF1877F2),
              ),
              onPressed: togglePlayPause,
            ),

            // Progress bar (reduced vertical padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3, // thinner track
                  activeTrackColor: Color(0xFF1877F2),
                  inactiveTrackColor: Colors.grey.shade700,
                  thumbColor: Color(0xFF1877F2),
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
            ),

            // Time text (smaller)
            Text(
              "${formatTime(current)} / ${formatTime(total)}",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),

            const SizedBox(height: 12),

            // Lyrics (more room)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 1,
                ), // less padding → wider space
                child: SingleChildScrollView(
                  child: Text(
                    song.lyrics,
                    style: const TextStyle(
                      fontSize: 20, // was 15 → increased
                      height: 1.55, // better readability
                      color: Colors.white,
                    ),
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
      color: Colors.grey.shade800,
      child: const Icon(Icons.music_note, color: Colors.white, size: 50),
    );
  }

  String formatTime(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}
//3