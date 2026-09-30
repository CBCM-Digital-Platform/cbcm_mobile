import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_button_row.dart';
import '../features/auth/domain/user_role.dart';
import '../features/auth/presentation/current_role_provider.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/mentee/dashboard/presentation/mentee_dashboard_page.dart';
import '../features/mentor/dashboard/presentation/mentor_dashboard_page.dart';
import 'app_routes.dart';
import '../core/offline/connectivity_service.dart';

// Temporary dev page, removed once real login and role routing are in place
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final connectivity = ref.watch(connectivityProvider);
    final roleNotifier = ref.read(currentRoleProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current role: ${role?.name ?? 'none'}'),
              Text('Connectivity: ${connectivity.name}'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => roleNotifier.setRole(UserRole.mentee),
                child: const Text('Set role: Mentee'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => roleNotifier.setRole(UserRole.mentor),
                child: const Text('Set role: Mentor'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => roleNotifier.setRole(null),
                child: const Text('Clear role'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Go to Login'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.menteeDashboard),
                child: const Text('Mentee Dashboard'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.mentorDashboard),
                child: const Text('Mentor Dashboard'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 320,
                child: Column(
                  children: [
                    AppButtonRow(
                      secondary: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.danger,
                        onPressed: () {},
                      ),
                      primary: AppButton(label: 'Save', onPressed: () {}),
                    ),
                    const SizedBox(height: 12),
                    AppButtonRow(
                      secondary: AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        onPressed: () {},
                      ),
                      primary: AppButton(label: 'Continue', onPressed: () {}),
                    ),
                    const SizedBox(height: 12),
                    AppButtonRow(
                      secondary: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.danger,
                        onPressed: () {},
                      ),
                      primary: AppButton(
                        label: 'Delete',
                        variant: AppButtonVariant.danger,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Tells the router to re-check redirects whenever the role changes
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentRoleProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final role = ref.read(currentRoleProvider);
      final path = state.matchedLocation;

      if (path.startsWith('/mentee') && role != UserRole.mentee) {
        return role == UserRole.mentor
            ? AppRoutes.mentorDashboard
            : AppRoutes.login;
      }
      if (path.startsWith('/mentor') && role != UserRole.mentor) {
        return role == UserRole.mentee
            ? AppRoutes.menteeDashboard
            : AppRoutes.login;
      }
      return null; // no redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.menteeDashboard,
        builder: (context, state) => const MenteeDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.mentorDashboard,
        builder: (context, state) => const MentorDashboardPage(),
      ),
    ],
  );
});