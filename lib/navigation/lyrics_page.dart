import 'package:flutter/material.dart';
import '../models/song.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class LyricsPage extends StatefulWidget {
  final Song song;
  const LyricsPage({super.key, required this.song});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late YoutubePlayerController _controller;
  bool isPlaying = false;
  Duration current = Duration.zero;
  Duration total = Duration.zero;

  @override
  void initState() {
    super.initState();

    final videoId = YoutubePlayer.convertUrlToId(widget.song.youtubeUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Auto play immediately
        mute: false,
        disableDragSeek: false,
        hideControls: true, // hide video controls
        hideThumbnail: true,
        isLive: false,
      ),
    );

    // Listen to player state
    _controller.addListener(() {
      if (!mounted) return;

      final value = _controller.value;
      final position = value.position;
      final duration = value.metaData.duration;

      setState(() {
        isPlaying = value.isPlaying;
        current = position;
        total = duration;
      });
    });
  }

  void togglePlayPause() {
    if (isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String formatTime(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Song image
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
            const SizedBox(height: 10),

            // Play/Pause Button
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 55,
                color: const Color(0xFF1877F2),
              ),
              onPressed: togglePlayPause,
            ),

            // Progress Bar
            if (total.inSeconds > 0)
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: const Color(0xFF1877F2),
                      inactiveTrackColor: Colors.grey.shade700,
                      thumbColor: const Color(0xFF1877F2),
                    ),
                    child: Slider(
                      min: 0,
                      max: total.inSeconds.toDouble(),
                      value: current.inSeconds.toDouble().clamp(
                        0,
                        total.inSeconds.toDouble(),
                      ),
                      onChanged: (value) {
                        _controller.seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Text(
                    "${formatTime(current)} / ${formatTime(total)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),

            // Hidden YouTube player (audio only)
            SizedBox(
              height: 0, // hide video
              child: YoutubePlayer(controller: _controller),
            ),

            // Lyrics scroll
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.lyrics,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.55,
                    color: Colors.white,
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
}
