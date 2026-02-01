# SP Gallery

A gallery app with freedom.

## Features

- Display images and videos from device gallery
- Grid layout with thumbnails
- Full-screen media viewer
- Video playback support
- Permission handling
- Material Design 3 UI
- **Rsync server sync** - Configure and sync media to remote rsync server
- **Dark mode support** - Toggle between light and dark themes
- **Adaptive layout** - Adjustable grid columns (2-5) for different screen sizes
- **Smooth animations** - Hero transitions and animated UI elements


## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run the app on a device or emulator:
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions:

#### Android
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `ACCESS_MEDIA_LOCATION`

#### iOS
- `NSPhotoLibraryUsageDescription`
- `NSCameraUsageDescription`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── providers/
│   ├── gallery_provider.dart # State management for gallery
│   └── settings_provider.dart # Settings and rsync config
├── screens/
│   ├── gallery_screen.dart   # Main gallery screen
│   └── settings_screen.dart  # Settings configuration
├── services/
│   └── rsync_service.dart    # Rsync sync functionality
└── widgets/
    ├── media_grid_item.dart  # Grid item widget
    └── media_viewer.dart     # Full-screen media viewer
```

## Dependencies

- `photo_manager`: Access device photo library
- `video_player`: Video playback
- `provider`: State management
- `permission_handler`: Permission handling
- `cached_network_image`: Image caching

## Usage

1. Grant gallery permissions when prompted
2. View your media in a grid layout
3. Tap any media item to view in full screen
4. Swipe between media items in full-screen mode
5. Use refresh button to reload media

### Rsync Sync Configuration

1. Go to Settings from the app menu
2. Enable "Rsync Sync" toggle
3. Configure server details:
   - Server address (e.g., example.com)
   - Username for SSH access
   - Password (stored securely)
   - Remote path on server (e.g., /backup/gallery)
4. Enable "Auto Sync" for automatic syncing
5. Use the sync button in the gallery to manually sync

### Customization

- **Dark Mode**: Toggle in Settings
- **Grid Layout**: Adjust columns (2-5) in Settings
- **Video Duration**: Shows video length in grid view
- **Hero Animations**: Smooth transitions when opening media

## License

This project is licensed under the MIT License.
