import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EmergencyVideoPart extends StatefulWidget {
  final String path;
  const EmergencyVideoPart({Key? key, required this.path}) : super(key: key);

  @override
  _EmergencyVideoPartState createState() => _EmergencyVideoPartState();
}

class _EmergencyVideoPartState extends State<EmergencyVideoPart> {
  late VideoPlayerController _controller;
  String? videoUrl;
  void fetchVideo(String url) {
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {}); // Refresh to display the video
      });
  }

  void fetchEmergencyData() async {
    setState(() {
      videoUrl = widget.path;
    });
    fetchVideo(widget.path);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchEmergencyData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width - 32,
          height: 250,
          color: Colors.grey,
          child: _controller.value.isInitialized
              ? ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, VideoPlayerValue value, child) {
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    );
                  },
                )
              : Center(child: CircularProgressIndicator()),
        ),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.blue,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.black12,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.replay),
              onPressed: () {
                _controller.seekTo(Duration.zero);
              },
            ),
          ],
        ),
      ],
    );
  }
}
