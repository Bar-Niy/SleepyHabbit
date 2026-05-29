import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';

class BackupService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static const String _backupFolderName = 'SleepyHabbit_Backups';
  static const String _lastBackupKey = 'last_backup_time';

  /// Sign in to Google
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Check if signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Perform backup to Google Drive
  Future<bool> backup() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      // Get or create backup folder
      final folderId = await _getOrCreateFolder(driveApi, _backupFolderName);

      // Get database file
      final dbFile = await DatabaseService.instance.getDatabaseFile();
      if (!await dbFile.exists()) return false;

      // Upload file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'sleepy_habbit_backup_$timestamp.db';

      final driveFile = drive.File()
        ..name = fileName
        ..parents = [folderId];

      final media = drive.Media(dbFile.openRead(), await dbFile.length());
      await driveApi.files.create(driveFile, uploadMedia: media);

      // Save last backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());

      // Clean up old backups (keep last 10)
      await _cleanOldBackups(driveApi, folderId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore from Google Drive
  Future<bool> restore({String? fileId}) async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final driveApi = drive.DriveApi(httpClient);

      // If no specific file, get the latest backup
      final targetFileId = fileId ?? await _getLatestBackupId(driveApi);
      if (targetFileId == null) return false;

      // Download file
      final response = await driveApi.files.get(
        targetFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Write to local database path
      final dbFile = await DatabaseService.instance.getDatabaseFile();
      
      // Close DB before overwriting
      await DatabaseService.instance.close();

      final sink = dbFile.openWrite();
      await response.stream.pipe(sink);
      await sink.close();

      // Reinitialize DB
      await DatabaseService.instance.initialize();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get last backup time
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastBackupKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  /// Check if auto-backup is due (every 24 hours)
  Future<bool> isBackupDue() async {
    final lastBackup = await getLastBackupTime();
    if (lastBackup == null) return true;
    return DateTime.now().difference(lastBackup).inHours >= 24;
  }

  /// Perform auto-backup if due
  Future<void> autoBackupIfDue() async {
    if (!isSignedIn) return;
    if (await isBackupDue()) {
      await backup();
    }
  }

  Future<String> _getOrCreateFolder(
      drive.DriveApi driveApi, String folderName) async {
    // Search for existing folder
    final result = await driveApi.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
    );

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    // Create folder
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await driveApi.files.create(folder);
    return created.id!;
  }

  Future<String?> _getLatestBackupId(drive.DriveApi driveApi) async {
    final folderId = await _getOrCreateFolder(driveApi, _backupFolderName);
    final result = await driveApi.files.list(
      q: "'$folderId' in parents and trashed=false",
      orderBy: 'createdTime desc',
      pageSize: 1,
    );
    return result.files?.firstOrNull?.id;
  }

  Future<void> _cleanOldBackups(
      drive.DriveApi driveApi, String folderId) async {
    final result = await driveApi.files.list(
      q: "'$folderId' in parents and trashed=false",
      orderBy: 'createdTime desc',
    );

    if (result.files != null && result.files!.length > 10) {
      for (int i = 10; i < result.files!.length; i++) {
        await driveApi.files.delete(result.files![i].id!);
      }
    }
  }

  /// Get list of available backups
  Future<List<Map<String, String>>> listBackups() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return [];

      final driveApi = drive.DriveApi(httpClient);
      final folderId = await _getOrCreateFolder(driveApi, _backupFolderName);
      final result = await driveApi.files.list(
        q: "'$folderId' in parents and trashed=false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      return result.files?.map((f) => {
                'id': f.id ?? '',
                'name': f.name ?? '',
                'date': f.createdTime?.toIso8601String() ?? '',
                'size': f.size ?? '0',
              }).toList() ??
          [];
    } catch (e) {
      return [];
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});
