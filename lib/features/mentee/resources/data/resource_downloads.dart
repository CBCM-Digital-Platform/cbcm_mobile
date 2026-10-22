import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/security/file_vault.dart';
import '../domain/learning_resource.dart';

enum DownloadStatus { none, downloading, downloaded, failed }

class DownloadInfo {
  const DownloadInfo({
    this.status = DownloadStatus.none,
    this.progress = 0,
    this.path,
    this.error,
  });

  final DownloadStatus status;
  final double progress; // 0 to 1
  final String? path; // the ENCRYPTED file
  final String? error;
}

/// Downloads resource files into private app storage, encrypts them, and
/// remembers which ones are on the phone.
class ResourceDownloads extends Notifier<Map<String, DownloadInfo>> {
  @override
  Map<String, DownloadInfo> build() {
    _restore();
    return const {};
  }

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/resources');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Finds encrypted files already on the phone, so they stay available
  /// after a restart. Anything that isn't an encrypted file (old plain
  /// copies, unfinished downloads) is deleted.
  Future<void> _restore() async {
    try {
      final dir = await _dir();
      final found = <String, DownloadInfo>{};
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (name.endsWith('.enc')) {
          found[name.substring(0, name.length - 4)] = DownloadInfo(
            status: DownloadStatus.downloaded,
            progress: 1,
            path: entity.path,
          );
        } else {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
      // Anything already in progress wins over what was found on disk.
      state = {...found, ...state};
    } catch (e) {
      debugPrint('[DOWNLOAD] could not read saved downloads: $e');
    }
  }

  void _set(String id, DownloadInfo info) => state = {...state, id: info};

  Future<void> download(LearningResource resource) async {
    final url = resource.downloadUrl;
    if (url == null) return;
    if (state[resource.id]?.status == DownloadStatus.downloading) return;

    _set(resource.id, const DownloadInfo(status: DownloadStatus.downloading));

    String? temp;
    String? target;
    try {
      final dir = await _dir();
      target = '${dir.path}/${resource.id}.enc';
      temp = '${dir.path}/${resource.id}.part';

      // A plain Dio for now. Files from the real backend will need the
      // signed-in Dio so the access token is attached.
      await Dio().download(
        url,
        temp,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _set(
              resource.id,
              DownloadInfo(
                status: DownloadStatus.downloading,
                progress: received / total,
              ),
            );
          }
        },
      );

      // Encrypt, then delete the readable copy.
      await ref
          .read(fileVaultProvider)
          .encryptFile(plainPath: temp, encryptedPath: target);
      await File(temp).delete();

      _set(
        resource.id,
        DownloadInfo(
          status: DownloadStatus.downloaded,
          progress: 1,
          path: target,
        ),
      );
    } catch (e) {
      debugPrint('[DOWNLOAD] ${resource.id} failed: $e');
      for (final p in [temp, target]) {
        if (p == null) continue;
        try {
          final f = File(p);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      _set(
        resource.id,
        const DownloadInfo(
          status: DownloadStatus.failed,
          error: 'Download failed. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> remove(String id) async {
    final path = state[id]?.path;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    final next = {...state}..remove(id);
    state = next;
  }
}

final resourceDownloadsProvider =
    NotifierProvider<ResourceDownloads, Map<String, DownloadInfo>>(
  ResourceDownloads.new,
);