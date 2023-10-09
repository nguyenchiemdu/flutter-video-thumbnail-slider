import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_slider/video_thumbnail_slider.dart';

class SeltectThumbnailPage extends StatefulWidget {
  const SeltectThumbnailPage({required this.media, Key? key}) : super(key: key);
  final File media;
  @override
  State<SeltectThumbnailPage> createState() => _SeltectThumbnailPageState();
}

class _SeltectThumbnailPageState extends State<SeltectThumbnailPage> {
  late VideoPlayerController videoController =
      VideoPlayerController.file(widget.media);

  Future<bool?> initVideoController() async {
    await videoController.initialize();
    return true;
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [CupertinoButton(child: const Text('Save'), onPressed: () {})],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              child: FutureBuilder(
                  future: initVideoController(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      return FittedVideoPlayer(
                        controller: videoController,
                        height: 400,
                      );
                    }
                    return const SizedBox();
                  }),
            ),
            const SizedBox(
              height: 16,
            ),
            VideoThumbnailSlider(
              controller: videoController,
              splitImage: 11,
              width: MediaQuery.of(context).size.width - 32,
              backgroundColor: const Color(0xff474545),
              frameBuilder: (imgData) => Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.black.withOpacity(0.1), width: 0.5)),
                child: Image.memory(
                  imgData,
                  fit: BoxFit.cover,
                ),
              ),
              customCurrentFrameBuilder: (videoController) => Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: const Color(0xFFFF5858), width: 4)),
                child: VideoPlayer(videoController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FittedVideoPlayer extends StatefulWidget {
  const FittedVideoPlayer(
      {required this.controller, this.height = 300, Key? key})
      : super(key: key);
  final VideoPlayerController controller;
  final double height;

  @override
  State<FittedVideoPlayer> createState() => _FittedVideoPlayerState();
}

class _FittedVideoPlayerState extends State<FittedVideoPlayer> {
  late double width = MediaQuery.of(context).size.width;
  late double height = widget.height;
  @override
  void initState() {
    super.initState();
  }

  void getVideoRatio() {
    if (widget.controller.value.isInitialized) {
      updateWidthHeight();
    }
  }

  void updateWidthHeight() {
    final ratio = widget.controller.value.aspectRatio;
    if (height * ratio <= width) {
      width = height * ratio;
    } else {
      height = width / ratio;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    updateWidthHeight();
    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: VideoPlayerView(
          videoController: widget.controller,
        ),
      ),
    );
  }
}

class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView(
      {this.videoController, this.media, this.autoPlay = true, Key? key})
      : super(key: key);
  final VideoPlayerController? videoController;
  final File? media;
  final bool autoPlay;
  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _videoController =
      widget.videoController ?? VideoPlayerController.file(widget.media!);
  @override
  void initState() {
    initVideoController();
    super.initState();
  }

  void initVideoController() async {
    if (!_videoController.value.isInitialized) {
      await _videoController.initialize();
    }
    setState(() {});
    if (widget.autoPlay) {
      _videoController.play();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onVideoTap() {
    if (_videoController.value.isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVideoTap,
      child: VideoPlayer(_videoController),
    );
  }
}
