import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/sessions_repository_provider.dart';

/// Fetches the Jitsi join token from the backend and launches the video meeting
/// in an in-app browser view or external browser.
Future<void> launchJitsiMeeting({
  required BuildContext context,
  required WidgetRef ref,
  required int sessionId,
  String? sessionTitle,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text('Preparing video room for ${sessionTitle ?? "session"}...'),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );

  try {
    final token = await ref.read(sessionsRepositoryProvider).getJoinToken(sessionId);
    final uri = Uri.parse(token.meetingUrl);

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );

    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('[launchJitsiMeeting] Error: $e');
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Could not open video meeting: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
