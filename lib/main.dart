import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:pdfrx/pdfrx.dart';
import 'core/network/server_warmup.dart';
import 'core/security/screen_security_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  await dotenv.load(fileName: '.env');

  // Enforce screen protection against screenshots and screen recording
  await ScreenSecurityService.initialize();

  // Warm up the server in the background while the splash screen is shown
  warmUpServer();

  runApp(const ProviderScope(child: App()));
}
