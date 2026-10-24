import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_response.dart';
import '../data/sessions_repository_provider.dart';

/// Fetches the Jitsi join token from the backend and opens the video meeting.
/// Only a room the server provides is ever opened.
Future<void> launchJitsiMeeting({
  required BuildContext context,
  required WidgetRef ref,
  required int sessionId,
  String? sessionTitle,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Preparing video room for ${sessionTitle ?? "session"}...'),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );

  try {
    final token =
        await ref.read(sessionsRepositoryProvider).getJoinToken(sessionId);

    if (token.domain.isEmpty || token.room.isEmpty || token.token.isEmpty) {
      throw ApiException(
        const ApiError(
          code: 'MEETING_UNAVAILABLE',
          message: 'The video meeting is not available for this session yet.',
        ),
      );
    }

    final uri = Uri.parse(token.meetingUrl);
    var launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!launched) {
      throw ApiException(
        const ApiError(
          code: 'LAUNCH_FAILED',
          message: 'Could not open the video meeting on this phone.',
        ),
      );
    }
  } on ApiException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(e.error.message), backgroundColor: Colors.red),
    );
  } catch (e) {
    debugPrint('[launchJitsiMeeting] Error: $e');
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not open the video meeting. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}