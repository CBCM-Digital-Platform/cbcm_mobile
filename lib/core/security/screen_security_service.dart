import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to prevent screenshots and screen recordings across the app,
/// protecting sensitive patient, mentee, and clinical data.
class ScreenSecurityService {
  ScreenSecurityService._();

  static const MethodChannel _channel = MethodChannel('cbcm/screen_security');
  static bool _isSecure = false;

  /// Returns whether screen security is currently active.
  static bool get isSecure => _isSecure;

  /// Enables screen capture prevention (FLAG_SECURE on Android, privacy masking on iOS).
  ///
  /// Screenshots will be blocked by the operating system, screen recordings
  /// will record a black screen, and the recent apps task switcher will be masked.
  static Future<bool> enableSecureMode() async {
    try {
      final res = await _channel.invokeMethod<bool>('enableSecure');
      _isSecure = res ?? true;
      debugPrint('[ScreenSecurity] Screen capture protection ENABLED.');
      return _isSecure;
    } on PlatformException catch (e) {
      debugPrint('[ScreenSecurity] Failed to enable secure mode: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[ScreenSecurity] Unexpected error: $e');
      return false;
    }
  }

  /// Disables screen capture prevention.
  static Future<bool> disableSecureMode() async {
    try {
      final res = await _channel.invokeMethod<bool>('disableSecure');
      _isSecure = !(res ?? true);
      debugPrint('[ScreenSecurity] Screen capture protection DISABLED.');
      return !_isSecure;
    } on PlatformException catch (e) {
      debugPrint('[ScreenSecurity] Failed to disable secure mode: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[ScreenSecurity] Unexpected error: $e');
      return false;
    }
  }

  /// Automatically initializes screen security.
  ///
  /// In Release/Production builds, protection is strictly enforced.
  /// In Debug mode, protection is active by default, but can be configured.
  static Future<void> initialize({bool forceInDebug = true}) async {
    if (kReleaseMode || forceInDebug) {
      await enableSecureMode();
    }
  }
}
