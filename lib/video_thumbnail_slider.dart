library video_thumbnail_slider;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_slider/frame_utils.dart';

class VideoThumbnailSlider extends StatefulWidget {
  final VideoPlayerController controller;
  final double height;
  final double width;
  final int splitImage;
  final Color backgroundColor;
  final Widget Function(VideoPlayerController)? customCurrentFrameBuilder;
  final Widget Function(Uint8List)? frameBuilder;

  const VideoThumbnailSlider({
    Key? key,
    required this.controller,
    this.height = 50,
    this.width = 350,
    this.splitImage = 7,
    this.customCurrentFrameBuilder,
    this.frameBuilder,
    this.backgroundColor = Colors.black,
  }) : super(key: key);
  @override
  VideoThumbnailSliderState createState() => VideoThumbnailSliderState();
}

class VideoThumbnailSliderState extends State<VideoThumbnailSlider> {
  double _slidePosition = 0.0;
  late final _height = widget.height;
  late final _width = widget.width;
  late final _splitImage = widget.splitImage;
  late final _videoController = widget.controller;
  void _onPositionChanged() async {
    if (_videoController.value.isPlaying) {
      final position = (await _videoController.position) ?? Duration.zero;
      setState(() {
        _slidePosition =
            position.inSeconds / _videoController.value.duration.inSeconds;
      });
    }
    if (_videoController.value.isCompleted) {
      setState(() {
        _slidePosition = 1;
      });
    }
  }

  void _onHorizontalDragSlider(DragUpdateDetails details) async {
    setState(() {
      // Calculate the new position of the slide rectangle based on drag
      _slidePosition += details.delta.dx / context.size!.width;
      _slidePosition = _slidePosition.clamp(0.0, 1.0);
    });
    final second = widget.controller.value.duration.inSeconds;
    await widget.controller.pause();
    await widget.controller
        .seekTo(Duration(seconds: (second * _slidePosition).ceil()));
  }

  @override
  void initState() {
    _videoController.addListener(() {
      _onPositionChanged();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        children: [
          Container(
            width: _width,
            height: _height,
            color: widget.backgroundColor,
            child: BackgroundSlider(
              controller: _videoController,
              splitThumb: _splitImage,
              frameBuilder: widget.frameBuilder,
            ),
          ),
          Positioned(
            left: (_width - _width / _splitImage) * _slidePosition,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragSlider,
              child: SizedBox(
                width: _width / _splitImage,
                height: _height,
                child:
                    widget.customCurrentFrameBuilder?.call(widget.controller) ??
                        VideoPlayer(widget.controller),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BackgroundSlider extends StatefulWidget {
  const BackgroundSlider(
      {required this.controller,
      required this.splitThumb,
      this.frameBuilder,
      super.key});
  final VideoPlayerController controller;
  final int splitThumb;
  final Widget Function(Uint8List)? frameBuilder;
  @override
  State<BackgroundSlider> createState() => _BackgroundSliderState();
}

class _BackgroundSliderState extends State<BackgroundSlider> {
  late final VideoPlayerController _videoController = widget.controller;
  List<Uint8List> listThumbnail = [];
  bool hasListThumbnail = false;
  @override
  void initState() {
    if (_videoController.value.isInitialized) {
      getListThumbnail();
    } else {
      _videoController.addListener(() {
        if (_videoController.value.isInitialized && !hasListThumbnail) {
          getListThumbnail();
        }
      });
    }
    super.initState();
  }

  void getListThumbnail() async {
    hasListThumbnail = true;
    final result = await FrameUtils().getListThumbnailIsolate(
        videoPath: _videoController.dataSource,
        duration: _videoController.value.duration,
        split: widget.splitThumb);
    setState(() {
      listThumbnail = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: listThumbnail
          .map((imgData) => Expanded(
              child: widget.frameBuilder?.call(imgData) ??
                  Image.memory(
                    imgData,
                    fit: BoxFit.cover,
                  )))
          .toList(),
    );
  }
}
