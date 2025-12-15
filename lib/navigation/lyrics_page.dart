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
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        hideControls: true,
        hideThumbnail: true,
        isLive: false,
      ),
    );

    _controller.addListener(() {
      if (!mounted) return;
      final value = _controller.value;
      setState(() {
        isPlaying = value.isPlaying;
        current = value.position;
        total = value.metaData.duration;
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
    final theme = Theme.of(context);
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
                errorBuilder: (_, __, ___) => placeholderImage(theme),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(song.artist, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),

            // Play/Pause Button
            IconButton(
              icon: Icon(
                isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 55,
                color: theme.primaryColor,
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
                      activeTrackColor: theme.primaryColor,
                      inactiveTrackColor: theme.primaryColor.withOpacity(0.3),
                      thumbColor: theme.primaryColor,
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
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

            // Hidden YouTube player (audio only)
            SizedBox(height: 0, child: YoutubePlayer(controller: _controller)),

            // Lyrics scroll
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  song.lyrics,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget placeholderImage(ThemeData theme) {
    return Container(
      width: 170,
      height: 170,
      color: theme.cardColor,
      child: Icon(
        Icons.music_note,
        color: theme.primaryColor.withOpacity(0.6),
        size: 50,
      ),
    );
  }
}
