import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
          },
          child: const Text('Ir para login'),
        ),
      ),
    );
  }
}
