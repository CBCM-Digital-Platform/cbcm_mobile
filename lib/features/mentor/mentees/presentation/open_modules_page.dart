import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../data/module_access_repository.dart';
import 'module_access_detail_page.dart';

String _msg(Object e) =>
    e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

class OpenModulesPage extends ConsumerWidget {
  const OpenModulesPage({
    super.key,
    required this.menteeId,
    required this.menteeName,
    this.embedded = false,
  });

  final int menteeId;
  final String menteeName;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(mentorAvailableModulesProvider);
    final assignedModulesAsync = ref.watch(menteeAssignedModulesProvider(menteeId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = modulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _msg(e),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : null,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.invalidate(mentorAvailableModulesProvider);
                  ref.invalidate(menteeAssignedModulesProvider(menteeId));
                },
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (modules) {
        if (modules.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 48,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No learning modules available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modules authorized for your facility will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final assignedSet = assignedModulesAsync.value ?? <int>{};

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mentorAvailableModulesProvider);
            ref.invalidate(menteeAssignedModulesProvider(menteeId));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header description
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Select a module to view its resources, assign specific learning materials, or view curriculum details for $menteeName.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),

              for (final module in modules) ...[
                _ModuleAccessCard(
                  module: module,
                  isFullAssigned: assignedSet.contains(module.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModuleAccessDetailPage(
                          moduleId: module.id,
                          moduleTitle: module.title,
                          menteeId: menteeId,
                          menteeName: menteeName,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Modules Access: $menteeName'),
      ),
      body: body,
    );
  }
}

class _ModuleAccessCard extends StatelessWidget {
  const _ModuleAccessCard({
    required this.module,
    required this.isFullAssigned,
    required this.onTap,
  });

  final ModuleItem module;
  final bool isFullAssigned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isFullAssigned
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkBorder : AppColors.border.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.menu_book,
                  color: isFullAssigned ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (module.thematicAreaName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              module.thematicAreaName!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        if (isFullAssigned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Fully Assigned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Tap to manage resources',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
