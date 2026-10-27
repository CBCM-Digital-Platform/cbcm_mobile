import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/security/offline_access.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/resource_downloads.dart';
import '../data/resource_providers.dart';
import '../domain/learning_resource.dart';
import 'protected_pdf_page.dart';

Future<void> _showAccessDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verify your access'),
      content: Text(
        'Your offline access period (${OfflineAccess.maxOfflineDays} days) '
        'has ended. Connect to the internet and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> _openResource(
  BuildContext context,
  WidgetRef ref,
  LearningResource resource,
  String path,
) async {
  final allowed = await ref.read(offlineAccessProvider.notifier).ensureAccess();
  if (!context.mounted) return;

  if (!allowed) {
    await _showAccessDialog(context);
    return;
  }

  if (resource.type == ResourceType.pdf) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProtectedPdfPage(title: resource.title, encryptedPath: path),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing audio and video inside the app is coming next.'),
      ),
    );
  }
}

Future<void> _readOnline(
    BuildContext context, WidgetRef ref, LearningResource r) async {
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);
  final allowed = await ref.read(offlineAccessProvider.notifier).ensureAccess();
  if (!context.mounted) return;
  if (!allowed) {
    await _showAccessDialog(context);
    return;
  }
  messenger.showSnackBar(const SnackBar(
    content: Text('Opening...'),
    duration: Duration(seconds: 2),
  ));
  try {
    final res = await Dio().get<List<int>>(
      r.downloadUrl!,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    if (!context.mounted) return;
    await nav.push(MaterialPageRoute(
      builder: (_) =>
          ProtectedPdfPage(title: r.title, bytes: bytes, resourceId: r.id),
    ));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Could not open. Check your connection, or download it to read offline.'),
    ));
  }
}

class ResourcesPage extends ConsumerStatefulWidget {
  const ResourcesPage({super.key});

  @override
  ConsumerState<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends ConsumerState<ResourcesPage> {
  String _query = '';
  ResourceType? _type; // null = any type
  bool _starredOnly = false;
  bool _downloadedOnly = false;

  @override
  void initState() {
    super.initState();
    // Opening the library while online re-verifies access, which restarts
    // the offline period. Fails quietly when offline.
    Future.microtask(
      () => ref.read(offlineAccessProvider.notifier).verifyNow(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(resourcesControllerProvider);
    final downloads = ref.watch(resourceDownloadsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Resource Library'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AccessBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                    fontSize: 14,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search resources...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  _chip(
                    'All',
                    _type == null && !_starredOnly && !_downloadedOnly,
                    () => setState(() {
                      _type = null;
                      _starredOnly = false;
                      _downloadedOnly = false;
                    }),
                  ),
                  _chip('Downloaded', _downloadedOnly,
                      () => setState(() => _downloadedOnly = !_downloadedOnly)),
                  _chip('Starred', _starredOnly,
                      () => setState(() => _starredOnly = !_starredOnly)),
                  _chip('PDF', _type == ResourceType.pdf,
                      () => setState(() => _type = ResourceType.pdf)),
                  _chip('Video', _type == ResourceType.video,
                      () => setState(() => _type = ResourceType.video)),
                  _chip('Audio', _type == ResourceType.audio,
                      () => setState(() => _type = ResourceType.audio)),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(resourcesControllerProvider),
                    child: const Text('Could not load resources. Try again'),
                  ),
                ),
                data: (all) {
                  final q = _query.trim().toLowerCase();
                  final shown = all.where((r) {
                    if (_starredOnly && !r.isStarred) return false;
                    if (_downloadedOnly &&
                        downloads[r.id]?.status != DownloadStatus.downloaded) {
                      return false;
                    }
                    if (_type != null && r.type != _type) return false;
                    if (q.isEmpty) return true;
                    return r.title.toLowerCase().contains(q) ||
                        r.category.toLowerCase().contains(q);
                  }).toList();

                  if (shown.isEmpty) {
                    return Center(
                      child: Text(_starredOnly
                          ? 'No starred resources yet. Tap the star on a resource.'
                          : _downloadedOnly
                              ? 'Nothing downloaded yet.'
                              : 'Nothing here yet. Your mentor assigns resources to you.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ResourceTile(resource: shown[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows how long downloaded files stay available offline.
class _AccessBanner extends ConsumerWidget {
  const _AccessBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(offlineAccessProvider);
    if (status.level == AccessLevel.checking) return const SizedBox.shrink();

    final expired = status.level == AccessLevel.expired;
    final color = expired ? Colors.red : AppColors.primary;
    final days = status.daysLeft;
    final text = expired
        ? 'Offline access has expired. Connect to the internet to verify '
            'your access.'
        : 'Offline access: $days ${days == 1 ? 'day' : 'days'} left';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              expired ? Icons.lock_clock : Icons.verified_user_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
            if (expired)
              TextButton(
                onPressed: () =>
                    ref.read(offlineAccessProvider.notifier).verifyNow(),
                child: const Text('Verify'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResourceTile extends ConsumerWidget {
  const _ResourceTile({required this.resource});
  final LearningResource resource;

  IconData get _icon => switch (resource.type) {
        ResourceType.pdf => Icons.picture_as_pdf_outlined,
        ResourceType.video => Icons.play_circle_outline,
        ResourceType.audio => Icons.headphones_outlined,
        ResourceType.other => Icons.insert_drive_file_outlined,
      };

  void _start(BuildContext context, WidgetRef ref) {
    if (!resource.isDownloadable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This file is not available for download yet.'),
        ),
      );
      return;
    }
    ref.read(resourceDownloadsProvider.notifier).download(resource);
  }

  Widget _action(BuildContext context, WidgetRef ref, DownloadInfo info) {
    switch (info.status) {
      case DownloadStatus.downloading:
        return SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: info.progress > 0 ? info.progress : null,
              ),
            ),
          ),
        );
      case DownloadStatus.downloaded:
        return PopupMenuButton<String>(
          tooltip: 'Downloaded',
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onSelected: (value) {
            if (value == 'open') {
              _openResource(context, ref, resource, info.path!);
            } else {
              ref.read(resourceDownloadsProvider.notifier).remove(resource.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'remove', child: Text('Remove download')),
          ],
        );
      case DownloadStatus.failed:
        return IconButton(
          tooltip: 'Retry',
          onPressed: () => _start(context, ref),
          icon: const Icon(Icons.refresh, color: Colors.red),
        );
      case DownloadStatus.none:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return IconButton(
          tooltip: 'Download',
          onPressed: () => _start(context, ref),
          icon: Icon(
            Icons.download_outlined,
            color: isDark ? AppColors.darkTextSecondary : null,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info =
        ref.watch(resourceDownloadsProvider)[resource.id] ?? const DownloadInfo();
    final downloaded = info.status == DownloadStatus.downloaded;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    VoidCallback? onTap;
    if (downloaded) {
      onTap = () => _openResource(context, ref, resource, info.path!);
    } else if (resource.type == ResourceType.pdf && resource.isDownloadable) {
      onTap = () => _readOnline(context, ref, resource);
    }

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${resource.category} • ${resource.sizeLabel}'
                    '${downloaded ? ' • Available offline' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                    ),
                  ),
                  if (info.status == DownloadStatus.failed)
                    Text(info.error ?? 'Download failed.',
                        style: const TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Star',
              onPressed: () => ref
                  .read(resourcesControllerProvider.notifier)
                  .toggleStar(resource.id),
              icon: Icon(
                resource.isStarred ? Icons.star : Icons.star_border,
                color: resource.isStarred
                    ? AppColors.pageIndicator
                    : (isDark ? AppColors.darkTextSecondary : Colors.grey),
              ),
            ),
            _action(context, ref, info),
          ],
        ),
      ),
    );
  }
}