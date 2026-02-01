import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaItem {
  final AssetEntity entity;
  final String? thumbnailUrl;

  MediaItem({required this.entity, this.thumbnailUrl});

  bool get isVideo => entity.type == AssetType.video;
  String get title => entity.title ?? 'Unknown';
  DateTime get createdAt => entity.createDateTime ?? DateTime.now();
}

class GalleryProvider extends ChangeNotifier {
  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  String? _error;

  List<MediaItem> get mediaItems => _mediaItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMediaItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Request permissions based on Android version
      final hasPermission = await _requestPermissions();
      
      if (!hasPermission) {
        _error = 'Gallery permissions are required to access media';
        return;
      }

      // Load media with proper error handling
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
      );
      
      if (albums.isNotEmpty) {
        final List<AssetEntity> assets = await albums[0].getAssetListRange(
          start: 0,
          end: 1000,
        );
        
        _mediaItems = assets.map((asset) => MediaItem(entity: asset)).toList();
        
        if (_mediaItems.isEmpty) {
          _error = 'No media found in gallery';
        }
      } else {
        _error = 'No albums found';
      }
    } catch (e) {
      _error = 'Failed to load media: ${e.toString()}';
      print('Gallery error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _requestPermissions() async {
    try {
      // Try to request photo and video permissions (Android 13+)
      final imagePermission = await Permission.photos.request();
      final videoPermission = await Permission.videos.request();
      
      // If either is granted, try to access gallery
      if (imagePermission.isGranted || videoPermission.isGranted) {
        return true;
      }
      
      // Fallback to storage permission for older Android versions
      final storagePermission = await Permission.storage.request();
      return storagePermission.isGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  Future<void> refreshMedia() async {
    await loadMediaItems();
  }

  Future<void> openAppSettings() async {
    try {
      await Permission.photos.request(); // This will open settings if permanently denied
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
