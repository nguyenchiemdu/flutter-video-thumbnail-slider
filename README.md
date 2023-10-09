# Video Thumbnail Slider

A Flutter package that provides a customizable video thumbnail slider widget. This widget allows you to display a slider with thumbnails generated from a video, making it easy to navigate and preview different parts of the video.

## Features

- Displays a video thumbnail slider with customizable settings.
- Supports custom frame builders for individual frames in the slider.
- Allows seeking to different parts of the video by interacting with the slider.

## Getting Started

To use this package, you need to add it to your Flutter project. Follow these steps:

1. Add the following dependency to your `pubspec.yaml` file:

   ```yaml
   dependencies:
     video_thumbnail_slider: ^1.0.0
   ```

2. Import the package in your Dart code:

   ```dart
   import 'package:video_thumbnail_slider/video_thumbnail_slider.dart';
   ```

3. Create an instance of `VideoPlayerController` to control the video playback:

   ```dart
   VideoPlayerController _controller = VideoPlayerController.network('http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');
   ```

4. Use the `VideoThumbnailSlider` widget in your Flutter UI:

   ```dart
   VideoThumbnailSlider(
     controller: _controller,
     height: 50,
     width: 350,
     splitImage: 7,
     backgroundColor: Colors.black,
     customCurrentFrameBuilder: (controller) => VideoPlayer(controller),
   )
   ```

## Usage

Here's a basic example of how to use the `VideoThumbnailSlider` widget:

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail_slider/video_thumbnail_slider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final VideoPlayerController _controller = VideoPlayerController.network('https://example.com/sample_video.mp4');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Video Thumbnail Slider Example'),
        ),
        body: Center(
          child: VideoThumbnailSlider(
            controller: _controller,
            height: 50,
            width: 350,
            splitImage: 7,
            backgroundColor: Colors.black,
            customCurrentFrameBuilder: (controller) => VideoPlayer(controller),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          },
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ),
    );
  }
}
```

## Additional Information

- [GitHub Repository](https://github.com/example/repo)

Feel free to contribute, report issues, or request features on the GitHub repository. We welcome your feedback and contributions!