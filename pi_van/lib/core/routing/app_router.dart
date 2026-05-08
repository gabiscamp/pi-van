import 'package:flutter/material.dart';

import '../../presentation/pages/create_sala_page.dart';
import '../../presentation/pages/home_driver_page.dart';
import '../../presentation/pages/home_student_page.dart';
import '../../presentation/pages/join_sala_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/register_page.dart';
import '../../presentation/pages/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String homeDriver = '/home-driver';
  static const String homeStudent = '/home-student';
  static const String joinSala = '/join-sala';
  static const String createSala = '/create-sala';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      //case AppRoutes.register:
       // return MaterialPageRoute(builder: (_) => const RegisterPage());
      case AppRoutes.homeDriver:
        return MaterialPageRoute(builder: (_) => const HomeDriverPage());
      case AppRoutes.homeStudent:
        return MaterialPageRoute(builder: (_) => const HomeStudentPage());
      case AppRoutes.joinSala:
        return MaterialPageRoute(builder: (_) => const JoinSalaPage());
      case AppRoutes.createSala:
        return MaterialPageRoute(builder: (_) => const CreateSalaPage());
      case AppRoutes.splash:
      default:
        return MaterialPageRoute(builder: (_) => const SplashPage());
    }
  }
}
