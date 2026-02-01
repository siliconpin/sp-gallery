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
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadMedia();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadMedia() {
    final currentItem = widget.mediaItems[_currentIndex];
    _isVideo = currentItem.isVideo;

    if (_isVideo) {
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _loadMedia();
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
        onPageChanged: _onPageChanged,
        itemCount: widget.mediaItems.length,
        itemBuilder: (context, index) {
          final mediaItem = widget.mediaItems[index];
          return _MediaItemViewer(
            mediaItem: mediaItem,
            isVideo: mediaItem.isVideo,
            videoController: mediaItem.isVideo ? _videoController : null,
          );
        },
      ),
    );
  }
}

class _MediaItemViewer extends StatelessWidget {
  final MediaItem mediaItem;
  final bool isVideo;
  final VideoPlayerController? videoController;

  const _MediaItemViewer({
    required this.mediaItem,
    required this.isVideo,
    this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    if (isVideo && videoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      );
    }

    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        boundaryMargin: const EdgeInsets.all(20),
        child: FutureBuilder<Uint8List?>(
          future: mediaItem.entity.originBytes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
              );
            }

            return Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
