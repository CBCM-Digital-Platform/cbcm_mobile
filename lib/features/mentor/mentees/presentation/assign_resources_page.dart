import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../../../mentee/resources/data/resource_assignments.dart';
import '../../../mentee/resources/data/resource_providers.dart';
import '../../../mentee/resources/domain/learning_resource.dart';

final _catalogProvider = FutureProvider.autoDispose<List<LearningResource>>(
  (ref) {
    ref.keepAlive();
    return ref.watch(resourceRepositoryProvider).getResources();
  },
);

class AssignResourcesPage extends ConsumerStatefulWidget {
  const AssignResourcesPage({
    super.key,
    required this.menteeId,
    required this.menteeName,
    this.embedded = false,
  });
  final int menteeId;
  final String menteeName;
  final bool embedded;

  @override
  ConsumerState<AssignResourcesPage> createState() => _State();
}

class _State extends ConsumerState<AssignResourcesPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final Set<String> _selected = {
    ...?ref.read(resourceAssignmentsProvider.notifier).idsFor(widget.menteeId),
  };
  String? _area;

  Future<void> _save() async {
    await ref.read(resourceAssignmentsProvider.notifier).setFor(widget.menteeId, _selected);
    try {
      await ref.read(resourceRepositoryProvider).assignToMentee(widget.menteeId, _selected);
    } catch (_) {}
    if (!mounted) return;
    if (!widget.embedded) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigned ${_selected.length} resource(s) to ${widget.menteeName}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final catalog = ref.watch(_catalogProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Could not load resources.')),
        data: (all) {
          final areas = {for (final r in all) r.category}.toList()..sort();
          final shown = [
            for (final r in all) if (_area == null || r.category == _area) r,
          ];
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    for (final a in [null, ...areas]) () {
                      final isSelected = _area == a;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkElevatedSurface : theme.colorScheme.surface),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => setState(() => _area = a),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                a ?? 'All areas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }(),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(
                        child: Text(
                          'No learning resources found.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final r in shown)
                            CheckboxListTile(
                              activeColor: AppColors.primary,
                              checkColor: theme.colorScheme.onPrimary,
                              value: _selected.contains(r.id),
                              title: Text(
                                r.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${r.category} • ${r.type.name}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              onChanged: (v) => setState(() =>
                                  v == true ? _selected.add(r.id) : _selected.remove(r.id)),
                            ),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppButtonRow(
                    secondary: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.danger,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    primary: AppButton(
                      label: 'Assign (${_selected.length})',
                      onPressed: _save,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Assign to ${widget.menteeName}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: body,
    );
  }
}
