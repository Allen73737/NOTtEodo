import 'dart:io';

import 'package:flutter/foundation.dart';

import '../enterprise/sanctuary_logger.dart';
import '../state/app_settings.dart';
import '../state/sanctuary_state.dart';
import 'cloudinary_media_service.dart';
import 'sanctuary_supabase_service.dart';

/// Copies photos and voice notes that exist only on this device to the signed-in
/// user's cloud folder, then points the item at the cloud copy.
///
/// Synced rows only carry a file path, so without this a reinstall (or a second
/// device) gets the pin, outfit or entry back without its picture or recording.
/// Runs after each successful sync; items whose files are gone are left alone.
class MediaBackupService {
  static final MediaBackupService _instance = MediaBackupService._internal();
  factory MediaBackupService() => _instance;
  MediaBackupService._internal();

  bool _running = false;

  /// Items still waiting for their file to be backed up, for the settings screen.
  final ValueNotifier<int> pending = ValueNotifier(0);

  static bool isLocalFile(String? path) =>
      path != null && path.isNotEmpty && !path.startsWith('http://') && !path.startsWith('https://') && !kIsWeb;

  static bool _exists(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Counts items whose media is still only on this device.
  int countPending(dynamic ref) {
    final pins = (ref.read(moodboardProvider) as List<MoodboardPin>).where((p) => isLocalFile(p.imageUrl) && _exists(p.imageUrl));
    final outfits = (ref.read(wardrobeProvider) as List<WardrobeOutfit>).where((o) => isLocalFile(o.imageUrl) && _exists(o.imageUrl!));
    final memoirs = (ref.read(journalProvider) as List<MemoirItem>).where((m) => isLocalFile(m.audioPath) && _exists(m.audioPath!));
    final avatar = (ref.read(appSettingsProvider) as AppSettings).avatarCustomPath;
    return pins.length + outfits.length + memoirs.length + (isLocalFile(avatar) && _exists(avatar!) ? 1 : 0);
  }

  /// Uploads everything pending. Returns how many files were backed up.
  Future<int> run(dynamic ref) async {
    if (_running || kIsWeb || !SanctuarySupabaseService().isConnectedToCloud) return 0;
    _running = true;
    var done = 0;
    final cloud = CloudinaryMediaService();
    try {
      Future<String?> upload(String path, String category) async {
        if (!_exists(path)) return null;
        final res = await cloud.uploadFile(file: File(path), category: category);
        return res == null || res.secureUrl.isEmpty ? null : res.secureUrl;
      }

      for (final p in [...ref.read(moodboardProvider) as List<MoodboardPin>]) {
        if (!isLocalFile(p.imageUrl)) continue;
        final url = await upload(p.imageUrl, 'moodboard');
        if (url != null) {
          ref.read(moodboardProvider.notifier).updatePin(p.id, imageUrl: url);
          done++;
        }
      }
      for (final o in [...ref.read(wardrobeProvider) as List<WardrobeOutfit>]) {
        if (!isLocalFile(o.imageUrl)) continue;
        final url = await upload(o.imageUrl!, 'wardrobe');
        if (url != null) {
          ref.read(wardrobeProvider.notifier).updateOutfit(o.id, imageUrl: url);
          done++;
        }
      }
      for (final m in [...ref.read(journalProvider) as List<MemoirItem>]) {
        if (!isLocalFile(m.audioPath)) continue;
        final url = await upload(m.audioPath!, 'audio');
        if (url != null) {
          (ref.read(journalProvider.notifier) as JournalNotifier).edit(m.id, (e) => e.copyWith(audioPath: url));
          done++;
        }
      }
      final avatar = (ref.read(appSettingsProvider) as AppSettings).avatarCustomPath;
      if (isLocalFile(avatar)) {
        final url = await upload(avatar!, 'avatars');
        if (url != null) {
          ref.read(appSettingsProvider.notifier).setAvatarCustomPath(url);
          done++;
        }
      }
      if (done > 0) SanctuaryLogger().info('MediaBackup', 'Backed up $done file(s) to the cloud.');
    } catch (e) {
      SanctuaryLogger().warn('MediaBackup', 'Backup paused: $e');
    } finally {
      _running = false;
      pending.value = countPending(ref);
    }
    return done;
  }
}
