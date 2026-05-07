import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PI Van',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
