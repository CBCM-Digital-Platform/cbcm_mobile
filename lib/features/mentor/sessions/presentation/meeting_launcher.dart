import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_response.dart';
import '../data/sessions_repository_provider.dart';

/// Fetches the Jitsi join token from the backend and opens the video meeting
/// in the user's web browser for full WebRTC camera and microphone support.
Future<void> launchJitsiMeeting({
  required BuildContext context,
  required WidgetRef ref,
  required int sessionId,
  String? sessionTitle,
  String? fallbackUrl,
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
            child: Text('Opening video meeting for ${sessionTitle ?? "session"}...'),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
    ),
  );

  try {
    String? meetingUrl;

    try {
      final token =
          await ref.read(sessionsRepositoryProvider).getJoinToken(sessionId);
      meetingUrl = token.meetingUrl;
    } catch (e) {
      debugPrint('[launchJitsiMeeting] Backend getJoinToken failed: $e');
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        meetingUrl = fallbackUrl;
      } else {
        meetingUrl = 'https://meet.jit.si/cbcm-session-$sessionId';
      }
    }

    if (meetingUrl.isEmpty) {
      meetingUrl = 'https://meet.jit.si/cbcm-session-$sessionId';
    }

    final uri = Uri.parse(meetingUrl);

    // Launch in the browser app so the web video room opens directly with camera & audio permissions
    var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
    if (!launched) {
      throw ApiException(
        const ApiError(
          code: 'LAUNCH_FAILED',
          message: 'Could not open the video meeting in your browser.',
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