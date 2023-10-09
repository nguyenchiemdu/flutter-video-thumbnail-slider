import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'dart:isolate';
import 'dart:async';

class FrameUtils {
  // Get a thumbnail image from a video at a specified position.
  Future<Uint8List?> getThumbnail(String videoPath,
      {Duration position = Duration.zero}) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        quality: 100,
        timeMs: position.inMilliseconds,
      );
      return uint8list;
    } catch (e, s) {
      // Handle any exceptions and print error information.
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      return null;
    }
  }

  // Get a list of thumbnails from a video at evenly spaced intervals.
  Future<List<Uint8List>> getListThumbnail({
    required String videoPath,
    required Duration duration,
    required int split,
  }) async {
    final jumpStep = duration.inSeconds / split ~/ 1;
    final List<Duration> timePoint = [];

    for (int second = 0; second < duration.inSeconds; second += jumpStep) {
      timePoint.add(Duration(seconds: second));
    }
    final listThumbnail = await Future.wait(timePoint
        .map((duration) => getThumbnail(videoPath, position: duration)));
    return listThumbnail.whereType<Uint8List>().toList();
  }

  // Generate thumbnails in an isolate and send them back to the main isolate.
  Future<void> generateThumbnails(Map<String, dynamic> data) async {
    // Ensure that the isolate's binary messenger is initialized.
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    final videoPath = data['videoPath'];
    final duration = data['duration'] as Duration;
    final split = data['split'];
    final jumpStep = (duration.inMilliseconds / split).ceil();
    final List<Duration> timePoint = [];
    for (int ms = 0; ms < duration.inMilliseconds; ms += jumpStep) {
      timePoint.add(Duration(milliseconds: ms));
    }

    final List<Uint8List> listThumbnail = [];

    for (var duration in timePoint) {
      final thumbnail = await getThumbnail(videoPath, position: duration);
      if (thumbnail != null) {
        listThumbnail.add(thumbnail);
      }
    }

    // Send the list of thumbnails back to the main isolate.
    data['sendPort'].send(listThumbnail);
  }

  late RootIsolateToken rootToken;

  // Get a list of thumbnails from a video using an isolate.
  Future<List<Uint8List>> getListThumbnailIsolate({
    required String videoPath,
    required Duration duration,
    required int split,
  }) async {
    final receivePort = ReceivePort();
    rootToken = RootIsolateToken.instance!;
    final isolateData = {
      'videoPath': videoPath,
      'duration': duration,
      'split': split,
      'sendPort': receivePort.sendPort,
    };

    await Isolate.spawn(generateThumbnails, isolateData);

    final List<Uint8List> listThumbnail = await receivePort.first;

    receivePort.close();

    return listThumbnail;
  }
}
