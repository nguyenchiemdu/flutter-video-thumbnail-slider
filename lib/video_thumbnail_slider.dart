library video_thumbnail_slider;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_slider/frame_utils.dart';

class VideoThumbnailSlider extends StatefulWidget {
  /// The controller for the video that this slider is controlling.
  final VideoPlayerController controller;

  /// The height of the video thumbnail slider.
  final double height;

  /// The width of the video thumbnail slider.
  final double width;

  /// The number of split images in the thumbnail slider.
  final int splitImage;

  /// The background color of the slider.
  final Color backgroundColor;

  /// A custom builder for the current frame of the video.
  final Widget Function(VideoPlayerController controller)?
      customCurrentFrameBuilder;

  /// A builder for the individual frames in the slider.
  final Widget Function(Uint8List imageData)? frameBuilder;

  /// Constructor for VideoThumbnailSlider.
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
  // The current position of the slider.
  double _slidePosition = 0.0;

  // The height of the video thumbnail slider.
  late final _height = widget.height;

  // The width of the video thumbnail slider.
  late final _width = widget.width;

  // The number of split images in the thumbnail slider.
  late final _splitImage = widget.splitImage;

  // The video controller for the video being displayed.
  late final _videoController = widget.controller;

  // Callback function when the video position changes.
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

  // Callback function when the user drags the slider horizontally.
  void _onHorizontalDragSlider(DragUpdateDetails details) async {
    setState(() {
      // Calculate the new position of the slide rectangle based on drag.
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
    // Add a listener to the video controller for position changes.
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
  const BackgroundSlider({
    required this.controller,
    required this.splitThumb,
    this.frameBuilder,
    Key? key,
  }) : super(key: key);

  // The video controller for the video being displayed.
  final VideoPlayerController controller;

  // The number of split images in the thumbnail slider.
  final int splitThumb;

  // A builder for the individual frames in the slider.
  final Widget Function(Uint8List)? frameBuilder;

  @override
  State<BackgroundSlider> createState() => _BackgroundSliderState();
}

class _BackgroundSliderState extends State<BackgroundSlider> {
  // The video controller for the video being displayed.
  late final VideoPlayerController _videoController = widget.controller;

  // List of thumbnail images.
  List<Uint8List> listThumbnail = [];

  // Flag indicating whether the list of thumbnails has been generated.
  bool hasListThumbnail = false;

  @override
  void initState() {
    if (_videoController.value.isInitialized) {
      // Generate the list of thumbnails if the video is initialized.
      getListThumbnail();
    } else {
      // Add a listener to the video controller to generate thumbnails when it's initialized.
      _videoController.addListener(() {
        if (_videoController.value.isInitialized && !hasListThumbnail) {
          getListThumbnail();
        }
      });
    }
    super.initState();
  }

  // Generate the list of thumbnails from the video.
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
