import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_button_row.dart';
import '../../../mentee/resources/data/resource_assignments.dart';
import '../../../mentee/resources/data/resource_providers.dart';
import '../../../mentee/resources/domain/learning_resource.dart';

final _catalogProvider = FutureProvider.autoDispose<List<LearningResource>>(
  (ref) => ref.watch(resourceRepositoryProvider).getResources(),
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

class _State extends ConsumerState<AssignResourcesPage> {
  late final Set<String> _selected = {
    ...ref.read(resourceAssignmentsProvider.notifier).idsFor(widget.menteeId),
  };
  String? _area;

  void _save() {
    ref.read(resourceAssignmentsProvider.notifier).setFor(widget.menteeId, _selected);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigned ${_selected.length} resource(s) to ${widget.menteeName}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(_catalogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.pageIndicator.withValues(alpha: 0.15)
                      : AppColors.pageIndicator.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.pageIndicator.withValues(alpha: isDark ? 0.35 : 0.6),
                  ),
                ),
                child: Text(
                  'Demo: approved resources are sample data and assignments '
                  'are kept on this phone until the backend is ready.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    for (final a in [null, ...areas]) () {
                      final isSelected = _area == a;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkElevatedSurface : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => setState(() => _area = a),
                            borderRadius: BorderRadius.circular(20),
                            splashColor: AppColors.primary.withValues(alpha: 0.2),
                            highlightColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                a ?? 'All areas',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
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
                child: ListView(
                  children: [
                    for (final r in shown)
                      CheckboxListTile(
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        value: _selected.contains(r.id),
                        title: Text(
                          r.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${r.category} • ${r.type.name}',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
