import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sp_gallery/providers/gallery_provider.dart';
import 'package:video_player/video_player.dart';

class MediaViewer extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.mediaItems,
    required this.initialIndex,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadVideo();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadVideo() {
    final currentItem = widget.mediaItems[_currentIndex];
    if (currentItem.isVideo) {
      _videoController?.dispose();
      final path = currentItem.entity.relativePath;
      if (path != null) {
        _videoController = VideoPlayerController.file(
          File(path),
        )..initialize().then((_) {
            setState(() {});
            _videoController?.play();
          });
      }
    } else {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${_currentIndex + 1} / ${widget.mediaItems.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaItems.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadVideo();
        },
        itemBuilder: (context, index) {
          final mediaItem = widget.mediaItems[index];
          return Center(
            child: mediaItem.isVideo
                ? _buildVideoViewer(mediaItem)
                : _buildImageViewer(mediaItem),
          );
        },
      ),
    );
  }

  Widget _buildImageViewer(MediaItem mediaItem) {
    return FutureBuilder<Uint8List?>(
      future: mediaItem.entity.originBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }

  Widget _buildVideoViewer(MediaItem mediaItem) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}
