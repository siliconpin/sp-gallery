import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sp_gallery/providers/settings_provider.dart';

class RsyncService {
  static Future<String> syncToServer(RsyncConfig config, List<String> filePaths) async {
    try {
      if (!config.enabled || config.server.isEmpty) {
        return 'Rsync is not configured or enabled';
      }

      // Build rsync command
      final remotePath = '${config.username}@${config.server}:${config.remotePath}';
      
      final command = 'rsync';
      final args = [
        '-avz', // archive, verbose, compress
        '--progress',
        '--password-file=${_createPasswordFile(config.password)}',
        ...filePaths,
        remotePath,
      ];

      if (kDebugMode) {
        print('Running rsync: $command ${args.join(' ')}');
      }

      final process = await Process.start(command, args);
      
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      // Clean up password file
      await _cleanupPasswordFile();

      if (exitCode == 0) {
        return 'Sync completed successfully';
      } else {
        return 'Sync failed: $stderr';
      }
    } catch (e) {
      return 'Sync error: $e';
    }
  }

  static Future<String> _createPasswordFile(String password) async {
    final tempDir = Directory.systemTemp;
    final passwordFile = File('${tempDir.path}/rsync_pass_${DateTime.now().millisecondsSinceEpoch}');
    await passwordFile.writeAsString(password);
    return passwordFile.path;
  }

  static Future<void> _cleanupPasswordFile() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = await tempDir.list().where((entity) => 
        entity is File && entity.path.contains('rsync_pass_')
      ).cast<File>().toList();
      
      for (final file in files) {
        try {
          await file.delete();
        } catch (e) {
          print('Error deleting password file: $e');
        }
      }
    } catch (e) {
      print('Error cleaning up password files: $e');
    }
  }

  static Future<bool> testConnection(RsyncConfig config) async {
    try {
      if (!config.enabled || config.server.isEmpty) {
        return false;
      }

      // Test SSH connection first
      final command = 'ssh';
      final args = [
        '-o', 'BatchMode=yes',
        '-o', 'ConnectTimeout=10',
        '${config.username}@${config.server}',
        'echo', 'connection_test',
      ];

      final process = await Process.start(command, args);
      final exitCode = await process.exitCode;

      return exitCode == 0;
    } catch (e) {
      if (kDebugMode) {
        print('Connection test failed: $e');
      }
      return false;
    }
  }

  static Future<String> getSyncStatus(List<String> filePaths) async {
    try {
      int totalFiles = filePaths.length;
      int syncedFiles = 0;
      int totalSize = 0;

      for (final filePath in filePaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            totalSize += await file.length();
            syncedFiles++;
          }
        } catch (e) {
          print('Error checking file $filePath: $e');
        }
      }

      return 'Ready to sync $syncedFiles files (${_formatBytes(totalSize)})';
    } catch (e) {
      return 'Error calculating sync status: $e';
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
