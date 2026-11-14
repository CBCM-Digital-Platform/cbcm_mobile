import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/module_access_repository.dart';

class ModuleAccessDetailPage extends ConsumerStatefulWidget {
  const ModuleAccessDetailPage({
    super.key,
    required this.moduleId,
    required this.moduleTitle,
    required this.menteeId,
    required this.menteeName,
  });

  final int moduleId;
  final String moduleTitle;
  final int menteeId;
  final String menteeName;

  @override
  ConsumerState<ModuleAccessDetailPage> createState() =>
      _ModuleAccessDetailPageState();
}

class _ModuleAccessDetailPageState extends ConsumerState<ModuleAccessDetailPage> {
  final Set<int> _busyResourceIds = {};
  bool _isFullModuleBusy = false;
  String? _actionError;

  String _msg(Object e) =>
      e is ApiException ? e.error.message : 'Action failed. Please try again.';

  Future<void> _toggleResource(int resourceId, bool assign) async {
    setState(() {
      _busyResourceIds.add(resourceId);
      _actionError = null;
    });

    final repo = ref.read(moduleAccessRepositoryProvider);
    try {
      if (assign) {
        await repo.assignResourceToMentee(
          resourceId,
          widget.menteeId,
          moduleId: widget.moduleId,
        );
      } else {
        await repo.revokeResourceFromMentee(
          resourceId,
          widget.menteeId,
          moduleId: widget.moduleId,
        );
      }
      ref.invalidate(menteeAssignedResourceIdsProvider(widget.menteeId));
      ref.invalidate(menteeAssignedModulesProvider(widget.menteeId));
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _msg(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_msg(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyResourceIds.remove(resourceId));
      }
    }
  }

  Future<void> _bulkAssign(List<ModuleResourceItem> resources, bool assign) async {
    final targetIds = resources.map((r) => r.id).toSet();
    setState(() {
      _busyResourceIds.addAll(targetIds);
      _actionError = null;
    });

    final repo = ref.read(moduleAccessRepositoryProvider);
    try {
      if (assign) {
        await repo.assignFullModule(widget.moduleId, widget.menteeId);
        for (final r in resources) {
          await repo.assignResourceToMentee(
            r.id,
            widget.menteeId,
            moduleId: widget.moduleId,
          );
        }
      } else {
        await repo.revokeFullModule(widget.moduleId, widget.menteeId);
        for (final r in resources) {
          await repo.revokeResourceFromMentee(
            r.id,
            widget.menteeId,
            moduleId: widget.moduleId,
          );
        }
      }
      ref.invalidate(menteeAssignedResourceIdsProvider(widget.menteeId));
      ref.invalidate(menteeAssignedModulesProvider(widget.menteeId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              assign
                  ? 'All resources in this module assigned to ${widget.menteeName}.'
                  : 'All resources in this module revoked from ${widget.menteeName}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _msg(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_msg(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyResourceIds.removeAll(targetIds));
      }
    }
  }

  Future<void> _toggleFullModule(bool assign) async {
    setState(() {
      _isFullModuleBusy = true;
      _actionError = null;
    });

    final repo = ref.read(moduleAccessRepositoryProvider);
    try {
      if (assign) {
        await repo.assignFullModule(widget.moduleId, widget.menteeId);
      } else {
        await repo.revokeFullModule(widget.moduleId, widget.menteeId);
      }
      ref.invalidate(menteeAssignedModulesProvider(widget.menteeId));
      ref.invalidate(menteeAssignedResourceIdsProvider(widget.menteeId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              assign
                  ? 'Full module assigned to ${widget.menteeName}.'
                  : 'Module assignment revoked from ${widget.menteeName}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = _msg(e));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_msg(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFullModuleBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.moduleTitle,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Mentee: ${widget.menteeName}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            tabs: const [
              Tab(
                icon: Icon(Icons.folder_shared_outlined),
                text: 'Resources',
              ),
              Tab(
                icon: Icon(Icons.info_outline),
                text: 'Details',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_actionError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.destructive.withValues(alpha: 0.12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.destructive, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _actionError!,
                        style: const TextStyle(
                            color: AppColors.destructive, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _actionError = null),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildResourcesTab(isDark),
                  _buildDetailsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: MODULE RESOURCES ACCESS & ASSIGNMENT
  // -------------------------------------------------------------
  Widget _buildResourcesTab(bool isDark) {
    final resourcesAsync = ref.watch(moduleResourcesProvider(widget.moduleId));
    final assignedModulesAsync =
        ref.watch(menteeAssignedModulesProvider(widget.menteeId));
    final assignedResourceIdsAsync =
        ref.watch(menteeAssignedResourceIdsProvider(widget.menteeId));

    final isFullAssigned =
        assignedModulesAsync.value?.contains(widget.moduleId) ?? false;
    final assignedResourceIds = assignedResourceIdsAsync.value ?? <int>{};

    return resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_msg(e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              AppButton(
                label: 'Try Again',
                onPressed: () {
                  ref.invalidate(moduleResourcesProvider(widget.moduleId));
                  ref.invalidate(menteeAssignedResourceIdsProvider(widget.menteeId));
                  ref.invalidate(menteeAssignedModulesProvider(widget.menteeId));
                },
              ),
            ],
          ),
        ),
      ),
      data: (resources) {
        // Calculate granted count
        final grantedCount = isFullAssigned
            ? resources.length
            : resources.where((r) => assignedResourceIds.contains(r.id)).length;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(moduleResourcesProvider(widget.moduleId));
            ref.invalidate(menteeAssignedResourceIdsProvider(widget.menteeId));
            ref.invalidate(menteeAssignedModulesProvider(widget.menteeId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary & Bulk Actions Banner
              AppCard(
                padding: const EdgeInsets.all(16),
                borderColor: isFullAssigned
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Module Resources (${resources.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFullAssigned || grantedCount > 0
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFullAssigned
                                ? 'Full Module Access'
                                : '$grantedCount of ${resources.length} Assigned',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFullAssigned || grantedCount > 0
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose specific resources to give access to for ${widget.menteeName}, or grant access to all resources in this module.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (resources.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _bulkAssign(resources, true),
                              icon: const Icon(Icons.select_all, size: 16),
                              label: const Text(
                                'Grant All',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _bulkAssign(resources, false),
                              icon: const Icon(Icons.deselect, size: 16),
                              label: const Text(
                                'Revoke All',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.destructive,
                                side: const BorderSide(color: AppColors.destructive),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Empty state
              if (resources.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No resources in this module',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final res in resources) ...[
                  _ResourceAccessTile(
                    resource: res,
                    isAssigned: isFullAssigned || assignedResourceIds.contains(res.id),
                    isBusy: _busyResourceIds.contains(res.id),
                    onToggle: (assign) => _toggleResource(res.id, assign),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MODULE DETAILS & METADATA
  // -------------------------------------------------------------
  Widget _buildDetailsTab(bool isDark) {
    final detailsAsync = ref.watch(moduleDetailsProvider(widget.moduleId));
    final assignedModulesAsync =
        ref.watch(menteeAssignedModulesProvider(widget.menteeId));

    return detailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_msg(e), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              AppButton(
                label: 'Try Again',
                onPressed: () =>
                    ref.invalidate(moduleDetailsProvider(widget.moduleId)),
              ),
            ],
          ),
        ),
      ),
      data: (module) {
        final isFullAssigned =
            assignedModulesAsync.value?.contains(widget.moduleId) ?? false;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Full Module Assignment Card
            AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: isFullAssigned
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Full Module Assignment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isFullAssigned
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFullAssigned ? 'Fully Assigned' : 'Individual Access',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFullAssigned
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFullAssigned
                        ? '${widget.menteeName} currently has complete access to this entire module curriculum.'
                        : 'Assigning the full module grants ${widget.menteeName} complete access to all lessons and materials in this module.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _isFullModuleBusy
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (isFullAssigned
                            ? OutlinedButton.icon(
                                onPressed: () => _toggleFullModule(false),
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: AppColors.destructive, size: 18),
                                label: const Text(
                                  'Revoke Full Module',
                                  style: TextStyle(
                                    color: AppColors.destructive,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.destructive),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                              )
                            : AppButton(
                                label: 'Assign Full Module',
                                icon: const Icon(Icons.add_task, size: 18),
                                onPressed: () => _toggleFullModule(true),
                              )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Module Metadata Card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Module Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (module.thematicAreaName != null) ...[
                    _InfoRow(
                      label: 'Thematic Area',
                      value: module.thematicAreaName!,
                    ),
                    const Divider(height: 16),
                  ],
                  if (module.estimatedDurationMinutes != null) ...[
                    _InfoRow(
                      label: 'Estimated Duration',
                      value: '${module.estimatedDurationMinutes} minutes',
                    ),
                    const Divider(height: 16),
                  ],
                  _InfoRow(
                    label: 'Status',
                    value: module.status.toUpperCase(),
                  ),
                  if (module.description != null &&
                      module.description!.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.description!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                  if (module.protocolSummary != null &&
                      module.protocolSummary!.isNotEmpty) ...[
                    const Divider(height: 16),
                    Text(
                      'Protocol Summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      module.protocolSummary!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResourceAccessTile extends StatelessWidget {
  const _ResourceAccessTile({
    required this.resource,
    required this.isAssigned,
    required this.isBusy,
    required this.onToggle,
  });

  final ModuleResourceItem resource;
  final bool isAssigned;
  final bool isBusy;
  final ValueChanged<bool> onToggle;

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'article':
        return Icons.article_outlined;
      case 'quiz':
        return Icons.quiz_outlined;
      case 'pdf':
      default:
        return Icons.picture_as_pdf_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForType(resource.type),
              color: AppColors.primary,
              size: 22,
            ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${resource.type.toUpperCase()}${resource.fileSize != null ? " • ${(resource.fileSize! / 1024).toStringAsFixed(0)} KB" : ""}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isBusy)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: isAssigned,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              onChanged: onToggle,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
