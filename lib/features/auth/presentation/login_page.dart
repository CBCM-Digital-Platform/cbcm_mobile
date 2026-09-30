import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_routes.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go(AppRoutes.home);
          },
          child: const Text('Back to Home'),
        ),
      ),
    );
  }
}