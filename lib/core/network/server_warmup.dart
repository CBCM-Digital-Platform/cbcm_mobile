import 'package:dio/dio.dart';
import '../../env/env_config.dart';

/// Free hosting puts the server to sleep when idle, and the first request
/// can take up to a minute. Pinging it as soon as the app opens wakes it up
/// while the user is still on the welcome and login screens.
Future<void> warmUpServer() async {
  try {
    final root =
        EnvConfig.apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '/');
    await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 70),
        receiveTimeout: const Duration(seconds: 70),
      ),
    ).get(root);
  } catch (_) {
    // Only a wake-up call. Failing here is fine.
  }
}