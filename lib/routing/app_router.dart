import '../features/certificates/presentation/certificates_page.dart';
import '../features/assessments/assessments_page.dart';
import '../features/help/presentation/help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/placeholder_page.dart';
import '../features/auth/domain/user_role.dart';
import '../features/auth/presentation/current_role_provider.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/must_change_password_provider.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/home/welcome_page.dart';
import '../features/mentee/dashboard/presentation/mentee_dashboard_page.dart';
import '../features/mentee/learning/domain/curriculum.dart';
import '../features/mentee/learning/presentation/learn_page.dart';
import '../features/mentee/learning/presentation/lesson_reader_page.dart';
import '../features/mentee/learning/presentation/module_detail_page.dart';
import '../features/mentee/mentorship/presentation/my_mentor_page.dart';
import '../features/mentee/presentation/mentee_shell.dart';
import '../features/mentee/quizzes/presentation/quiz_page.dart';
import '../features/logbook/presentation/mentee_logbook_page.dart';
import '../features/mentee/resources/presentation/resources_page.dart';
import '../features/mentor/dashboard/presentation/mentor_dashboard_page.dart';
import '../features/mentor/mentees/presentation/mentees_page.dart';
import '../features/mentor/presentation/mentor_shell.dart';
import '../features/mentor/sessions/presentation/mentor_sessions_page.dart';
import '../features/messaging/presentation/conversations_page.dart';
import '../features/mentee/settings/presentation/settings_page.dart';
import '../features/profile/presentation/profile_page.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentRoleProvider, (previous, next) => refresh.value++);
  ref.listen(mustChangePasswordProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  String dashboardFor(UserRole role) => role == UserRole.mentee
      ? AppRoutes.menteeDashboard
      : AppRoutes.mentorDashboard;

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    // Synchronous on purpose: no storage reads on navigation.
    redirect: (context, state) {
      final role = ref.read(currentRoleProvider);
      final mustChange = ref.read(mustChangePasswordProvider);
      final path = state.matchedLocation;

      // Signed out: only the welcome and login screens.
      if (role == null) {
        final isPublic = path == AppRoutes.home || path == AppRoutes.login;
        return isPublic ? null : AppRoutes.login;
      }

      // Signed in with a temporary password: only the reset screen.
      if (mustChange) {
        return path == AppRoutes.resetPassword ? null : AppRoutes.resetPassword;
      }

      // Signed in: skip the public screens.
      if (path == AppRoutes.home ||
          path == AppRoutes.login ||
          path == AppRoutes.resetPassword) {
        return dashboardFor(role);
      }

      if (path.startsWith('/mentee') && role != UserRole.mentee) {
        return dashboardFor(role);
      }
      if (path.startsWith('/mentor') && role != UserRole.mentor) {
        return dashboardFor(role);
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
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: AppRoutes.moduleDetail,
        builder: (context, state) {
          final module = state.extra;
          if (module is! CurriculumModule) {
            // Data lost (e.g. page reload): send back instead of crashing.
            return const _RedirectToMenteeHome();
          }
          return ModuleDetailPage(module: module);
        },
      ),
      GoRoute(
        path: AppRoutes.lessonReader,
        builder: (context, state) {
          final lesson = state.extra;
          if (lesson is! Lesson) return const _RedirectToMenteeHome();
          return LessonReaderPage(lesson: lesson);
        },
      ),
      GoRoute(
        path: AppRoutes.menteeResources,
        builder: (context, state) => const ResourcesPage(),
      ),
      GoRoute(
        path: AppRoutes.menteeQuiz,
        builder: (context, state) => const QuizPage(),
      ),
      GoRoute(
        path: AppRoutes.menteeLogbook,
        builder: (context, state) => const MenteeLogbookPage(),
      ),
      GoRoute(
        path: AppRoutes.menteeAssessments,
        builder: (context, state) => const AssessmentsPage(),
      ),
      GoRoute(
        path: AppRoutes.menteeCertificates,
        builder: (context, state) => const CertificatesPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MenteeShell(navigationShell: navigationShell),
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
              builder: (context, state) => const LearnPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.menteeMessages,
              builder: (context, state) => const ConversationsPage(),
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
              builder: (context, state) => const MyMentorPage(),
            ),
          ]),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MentorShell(navigationShell: navigationShell),
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
              builder: (context, state) => const MenteesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorSessions,
              builder: (context, state) => const MentorSessionsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.mentorMessages,
              builder: (context, state) => const ConversationsPage(),
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