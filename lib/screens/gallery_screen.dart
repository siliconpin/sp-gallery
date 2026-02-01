import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sp_gallery/providers/gallery_provider.dart';
import 'package:sp_gallery/providers/settings_provider.dart';
import 'package:sp_gallery/widgets/media_grid_item.dart';
import 'package:sp_gallery/widgets/media_viewer.dart';
import 'package:sp_gallery/screens/settings_screen.dart';
import 'package:sp_gallery/services/rsync_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadMediaItems();
      context.read<SettingsProvider>().loadSettings();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _syncMedia() async {
    final settings = context.read<SettingsProvider>();
    final gallery = context.read<GalleryProvider>();
    
    if (!settings.rsyncConfig.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rsync is not enabled in settings')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Syncing media...'),
          ],
        ),
      ),
    );

    try {
      // Get file paths from media items
      final filePaths = gallery.mediaItems
          .map((item) => item.entity.relativePath)
          .where((path) => path?.isNotEmpty == true)
          .cast<String>()
          .toList();

      final result = await RsyncService.syncToServer(settings.rsyncConfig, filePaths);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 32,
              height: 32,
              placeholderBuilder: (context) => const Icon(Icons.photo_library, size: 32),
            ),
            const SizedBox(width: 8),
            const Text('SP Gallery'),
          ],
        ),
        actions: [
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              if (settings.rsyncConfig.enabled) {
                return IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: _syncMedia,
                  tooltip: 'Sync to server',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GalleryProvider>().refreshMedia();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<GalleryProvider, SettingsProvider>(
        builder: (context, gallery, settings, child) {
          if (gallery.isLoading || settings.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gallery.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Permission Required',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      gallery.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => gallery.loadMediaItems(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (gallery.mediaItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No media found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Grant gallery permissions to see your photos and videos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              return GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: settings.gridColumns,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: gallery.mediaItems.length,
                itemBuilder: (context, index) {
                  final mediaItem = gallery.mediaItems[index];
                  return Hero(
                    tag: 'media_${mediaItem.entity.id}',
                    child: MediaGridItem(
                      mediaItem: mediaItem,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                MediaViewer(
                                  mediaItems: gallery.mediaItems,
                                  initialIndex: index,
                                ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
