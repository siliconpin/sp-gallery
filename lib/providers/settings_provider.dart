import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RsyncConfig {
  final String server;
  final String username;
  final String password;
  final String remotePath;
  final bool enabled;
  final bool autoSync;

  RsyncConfig({
    required this.server,
    required this.username,
    required this.password,
    required this.remotePath,
    this.enabled = false,
    this.autoSync = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'username': username,
      'remotePath': remotePath,
      'enabled': enabled,
      'autoSync': autoSync,
    };
  }

  factory RsyncConfig.fromJson(Map<String, dynamic> json) {
    return RsyncConfig(
      server: json['server'] ?? '',
      username: json['username'] ?? '',
      password: '', // Never store password in regular prefs
      remotePath: json['remotePath'] ?? '',
      enabled: json['enabled'] ?? false,
      autoSync: json['autoSync'] ?? false,
    );
  }
}

class SettingsProvider extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  static const String _rsyncConfigKey = 'rsync_config';
  static const String _darkModeKey = 'dark_mode';
  static const String _gridColumnsKey = 'grid_columns';

  RsyncConfig _rsyncConfig = RsyncConfig(
    server: '',
    username: '',
    password: '',
    remotePath: '',
  );
  bool _isDarkMode = false;
  int _gridColumns = 3;
  bool _isLoading = false;

  RsyncConfig get rsyncConfig => _rsyncConfig;
  bool get isDarkMode => _isDarkMode;
  int get gridColumns => _gridColumns;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load rsync config
      final rsyncConfigJson = prefs.getString(_rsyncConfigKey);
      if (rsyncConfigJson != null) {
        final config = RsyncConfig.fromJson(
          Map<String, dynamic>.from(
            // This is a simplified approach - in real app, use proper JSON parsing
            {'server': '', 'username': '', 'remotePath': '', 'enabled': false, 'autoSync': false}
          ),
        );
        
        // Load password from secure storage
        final password = await _secureStorage.read(key: 'rsync_password');
        _rsyncConfig = RsyncConfig(
          server: prefs.getString('rsync_server') ?? '',
          username: prefs.getString('rsync_username') ?? '',
          password: password ?? '',
          remotePath: prefs.getString('rsync_remote_path') ?? '',
          enabled: prefs.getBool('rsync_enabled') ?? false,
          autoSync: prefs.getBool('rsync_auto_sync') ?? false,
        );
      }

      // Load dark mode
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;

      // Load grid columns
      _gridColumns = prefs.getInt(_gridColumnsKey) ?? 3;
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRsyncConfig(RsyncConfig config) async {
    _rsyncConfig = config;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('rsync_server', config.server);
      await prefs.setString('rsync_username', config.username);
      await prefs.setString('rsync_remote_path', config.remotePath);
      await prefs.setBool('rsync_enabled', config.enabled);
      await prefs.setBool('rsync_auto_sync', config.autoSync);
      
      // Store password securely
      if (config.password.isNotEmpty) {
        await _secureStorage.write(key: 'rsync_password', value: config.password);
      }
    } catch (e) {
      print('Error saving rsync config: $e');
    }
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      print('Error saving dark mode: $e');
    }
  }

  Future<void> updateGridColumns(int columns) async {
    _gridColumns = columns;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_gridColumnsKey, columns);
    } catch (e) {
      print('Error saving grid columns: $e');
    }
  }
}
