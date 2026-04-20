import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerScreen({super.key, required this.videoUrl, this.title});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _vpController;
  ChewieController? _chewieController;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _vpController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _vpController.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _vpController,
          autoPlay: true,
          looping: false,
          aspectRatio: _vpController.value.aspectRatio,
          errorBuilder: (_, msg) => Center(
            child: Text(msg, style: const TextStyle(color: Colors.white)),
          ),
        );
      });
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _vpController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.title != null
            ? Text(widget.title!, style: const TextStyle(color: Colors.white))
            : null,
      ),
      body: Center(
        child: _error
            ? const Text('Could not load video.',
                style: TextStyle(color: Colors.white70))
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
