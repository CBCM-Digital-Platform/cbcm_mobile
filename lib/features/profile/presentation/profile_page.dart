import 'package:go_router/go_router.dart';
import '../../../routing/app_routes.dart';
import '../../auth/presentation/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../data/user_profile_repository.dart';

String _msg(Object e) =>
    e is ApiException ? e.error.message : 'Something went wrong. Please try again.';

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'settings') {
                context.push(AppRoutes.settings);
              } else if (val == 'help') {
                context.push(AppRoutes.help);
              } else if (val == 'logout') {
                confirmAndLogout(context, ref);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Help & support'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.destructive),
                    SizedBox(width: 12),
                    Text('Log out', style: TextStyle(color: AppColors.destructive)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_msg(e), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => ref.invalidate(userProfileProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (p) => _ProfileForm(profile: p),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final UserProfileData profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone);
  late final _qual = TextEditingController(text: widget.profile.qualification);
  late bool _notifications = widget.profile.notificationsEnabled;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _qual.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      await ref.read(userProfileRepositoryProvider).saveProfile(
            fullName: name,
            phone: _phone.text.trim(),
            qualification: _qual.text.trim(),
          );
      // Keeps the greeting on the dashboards in step with the new name.
      await ref.read(secureStorageProvider).write(StorageKeys.userName, name);
      ref.invalidate(userProfileProvider);
      if (mounted) _snack('Profile updated.');
    } catch (e) {
      if (mounted) _snack(_msg(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _notifications = value);
    try {
      await ref.read(userProfileRepositoryProvider).setNotifications(
            value,
            language: widget.profile.language,
            theme: widget.profile.theme,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _notifications = !value);
      _snack(_msg(e));
    }
  }

  Widget _readOnly(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final initials = p.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Enter your full name.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              return RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch(t)
                  ? null
                  : 'Enter a valid phone number.';
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _qual,
            decoration: const InputDecoration(labelText: 'Highest qualification'),
          ),
          const SizedBox(height: 20),
          _readOnly('Email', p.email),
          _readOnly('Role', _cap(p.role)),
          _readOnly('Account status', _cap(p.status)),
          _readOnly('Training status', _cap(p.trainingStatus)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: _toggle,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _saving ? 'Saving...' : 'Save changes',
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}