import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/theme/colors.dart';
import '../data/module_access_repository.dart';

final _modulesProvider = FutureProvider.autoDispose<List<LearningModuleRef>>(
  (ref) => ref.watch(moduleAccessRepositoryProvider).modules(),
);

final _grantedProvider = FutureProvider.autoDispose.family<Set<int>, int>(
  (ref, menteeId) => ref.watch(moduleAccessRepositoryProvider).grantedTo(menteeId),
);

String _msg(Object e) =>
    e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

class OpenModulesPage extends ConsumerStatefulWidget {
  const OpenModulesPage({super.key, required this.menteeId, required this.menteeName});
  final int menteeId;
  final String menteeName;

  @override
  ConsumerState<OpenModulesPage> createState() => _OpenModulesPageState();
}

class _OpenModulesPageState extends ConsumerState<OpenModulesPage> {
  final _local = <int, bool>{};
  final _busy = <int>{};

  Future<void> _toggle(int moduleId, bool value) async {
    setState(() {
      _local[moduleId] = value;
      _busy.add(moduleId);
    });
    final repo = ref.read(moduleAccessRepositoryProvider);
    try {
      if (value) {
        await repo.grant(moduleId, widget.menteeId);
      } else {
        await repo.revoke(moduleId, widget.menteeId);
      }
      ref.invalidate(_grantedProvider(widget.menteeId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _local.remove(moduleId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg(e))));
    } finally {
      if (mounted) setState(() => _busy.remove(moduleId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(_modulesProvider);
    final granted = ref.watch(_grantedProvider(widget.menteeId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Modules for ${widget.menteeName}',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: modules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_msg(e), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(_modulesProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No modules available. Ask your administrator to give you '
                  'access to modules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final open = granted.value ?? const <int>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (granted.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Could not check current access: ${_msg(granted.error!)}',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              for (final m in list)
                Card(
                  child: SwitchListTile(
                    activeThumbColor: AppColors.primary,
                    title: Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      (_local[m.id] ?? open.contains(m.id)) ? 'Open' : 'Closed',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _local[m.id] ?? open.contains(m.id),
                    onChanged: _busy.contains(m.id) ? null : (v) => _toggle(m.id, v),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}