import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoDialogtl extends StatefulWidget {
  const VideoDialogtl({super.key});

  @override
  State<VideoDialogtl> createState() => _VideoDialogtlState();
}

class _VideoDialogtlState extends State<VideoDialogtl> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      "assets/video/demo_team_leader.mp4",
    )
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}