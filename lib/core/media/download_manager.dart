/// Foundation only. Real encrypted, license-checked downloads are built
/// in Week 4 alongside protected resource downloads.
class DownloadManager {
  DownloadManager();

  final Set<String> _downloading = {};

  bool isDownloading(String resourceId) => _downloading.contains(resourceId);

  void markStarted(String resourceId) => _downloading.add(resourceId);

  void markFinished(String resourceId) => _downloading.remove(resourceId);
}