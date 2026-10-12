import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/offline/connectivity_service.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_button_row.dart';
import '../core/widgets/placeholder_page.dart';
import '../features/auth/domain/user_role.dart';
import '../features/auth/presentation/current_role_provider.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/mentee/dashboard/presentation/mentee_dashboard_page.dart';
import '../features/mentee/learning/domain/curriculum.dart';
import '../features/mentee/learning/presentation/lesson_reader_page.dart';
import '../features/mentee/learning/presentation/module_detail_page.dart';
import '../features/mentee/presentation/mentee_shell.dart';
import '../features/mentor/dashboard/presentation/mentor_dashboard_page.dart';
import '../features/mentor/presentation/mentor_shell.dart';
import 'app_routes.dart';
import '../features/home/welcome_page.dart';

// Temporary dev page, removed once Mentee/Mentor dashboards are real
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final connectivity = ref.watch(connectivityProvider);

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
              const SizedBox(height: 24),
              if (role == null)
                FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Go to Login'),
                )
              else ...[
                FilledButton(
                  onPressed: () => context.go(
                    role == UserRole.mentee
                        ? AppRoutes.menteeDashboard
                        : AppRoutes.mentorDashboard,
                  ),
                  child: const Text('Go to Dashboard'),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.danger,
                  onPressed: () =>
                      ref.read(currentRoleProvider.notifier).logout(),
                ),
              ],
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
      return null;
    },
    routes: [
           GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
                GoRoute(
        path: AppRoutes.moduleDetail,
        builder: (context, state) {
          final module = state.extra;
          if (module is! CurriculumModule) {
            // Data lost (e.g. page reload) — send back instead of crashing
            return const _RedirectToMenteeHome();
          }
          return ModuleDetailPage(module: module);
        },
      ),
      GoRoute(
        path: AppRoutes.lessonReader,
        builder: (context, state) {
          final lesson = state.extra;
          if (lesson is! Lesson) {
            return const _RedirectToMenteeHome();
          }
          return LessonReaderPage(lesson: lesson);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MenteeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeDashboard,
              builder: (context, state) => const MenteeDashboardPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeLearn,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Learn'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeMessages,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Message'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeAiAssist,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'AI Assist'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeMentorChat,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Mentor'),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MentorShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorDashboard,
              builder: (context, state) => const MentorDashboardPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorMentees,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Mentees'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorSessions,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Sessions'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorMessages,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Message'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorAskAi,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Ask AI'),
            ),
          ]),
        ],
      ),
    ],
  );
});
class _RedirectToMenteeHome extends StatelessWidget {
  const _RedirectToMenteeHome();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.menteeDashboard);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}