import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../routing/app_routes.dart';
import 'current_role_provider.dart';

enum _Strength { empty, weak, fair, strong }

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  _Strength _strength = _Strength.empty;
  String? _errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _strength = _Strength.empty;
      } else if (value.length < 8) {
        _strength = _Strength.weak;
      } else if (value.length < 12 ||
          !RegExp(r'[A-Z]').hasMatch(value) ||
          !RegExp(r'[0-9]').hasMatch(value)) {
        _strength = _Strength.fair;
      } else {
        _strength = _Strength.strong;
      }
    });
  }

  void _submit() {
    setState(() => _errorText = null);

    if (_currentPasswordController.text.isEmpty) {
      setState(() => _errorText = 'Enter your current password.');
      return;
    }
    // TODO(backend integration): verify current password via
    // ApiEndpoints.changePassword / AuthRepository once the backend is live.
    // Mocked for now: any non-empty current password is accepted.

    if (_newPasswordController.text.length < 12 ||
        _strength == _Strength.weak ||
        _strength == _Strength.fair) {
      setState(() => _errorText =
          'New password must be at least 12 characters and include '
          'uppercase, lowercase, numbers, and symbols.');
      return;
    }

    if (_newPasswordController.text != _confirmController.text) {
      setState(() => _errorText = 'New passwords do not match.');
      return;
    }

    if (_newPasswordController.text == _currentPasswordController.text) {
      setState(() => _errorText = 'New password must be different from your current password.');
      return;
    }

    final role = ref.read(currentRoleProvider);
    context.go(role?.name == 'mentee'
        ? AppRoutes.menteeDashboard
        : AppRoutes.mentorDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined,
                        color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For security reasons, your new password must be at '
                    'least 12 characters long and include a mix of '
                    'uppercase, lowercase, numbers, and symbols.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Password',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            hintText: 'Enter your current password',
                            prefixIcon: const Icon(Icons.lock_person_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCurrent
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('New Password',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          onChanged: _onPasswordChanged,
                          decoration: InputDecoration(
                            hintText: 'Enter new password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _StrengthBar(strength: _strength),
                        const SizedBox(height: 20),
                        const Text('Confirm New Password',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            hintText: 'Re-enter new password',
                            prefixIcon: const Icon(Icons.replay_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorText!,
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Update Password',
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final _Strength strength;

  @override
  Widget build(BuildContext context) {
    final filled = switch (strength) {
      _Strength.empty => 0,
      _Strength.weak => 1,
      _Strength.fair => 2,
      _Strength.strong => 3,
    };
    final label = switch (strength) {
      _Strength.empty => '',
      _Strength.weak => 'Weak',
      _Strength.fair => 'Fair',
      _Strength.strong => 'Strong',
    };
    final color = switch (strength) {
      _Strength.empty => Colors.grey.shade300,
      _Strength.weak => Colors.red,
      _Strength.fair => Colors.amber,
      _Strength.strong => Colors.green,
    };

    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 8),
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? color : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}