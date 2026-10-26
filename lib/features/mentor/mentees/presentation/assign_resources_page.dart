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
  });
  final int menteeId;
  final String menteeName;

  @override
  ConsumerState<AssignResourcesPage> createState() => _State();
}

class _State extends ConsumerState<AssignResourcesPage> {
  late final Set<String> _selected = {
    ...?ref.read(resourceAssignmentsProvider)[widget.menteeId],
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Assign to ${widget.menteeName}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: catalog.when(
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
                  color: AppColors.pageIndicator.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Demo: approved resources are sample data and assignments '
                  'are kept on this phone until the backend is ready.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final a in [null, ...areas])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(a ?? 'All areas'),
                          selected: _area == a,
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _area == a ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) => setState(() => _area = a),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final r in shown)
                      CheckboxListTile(
                        activeColor: AppColors.primary,
                        value: _selected.contains(r.id),
                        title: Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${r.category} • ${r.type.name}'),
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
      ),
    );
  }
}
