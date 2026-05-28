import 'package:flutter/material.dart';

import '../../presentation/pages/shared/splash_page.dart';
import '../../presentation/pages/shared/landing_page.dart';
import '../../presentation/pages/shared/login_page.dart';
import '../../presentation/pages/shared/register_page.dart';
import '../../presentation/pages/shared/profile_page.dart';
import '../../presentation/pages/student/student_shell.dart';
import '../../presentation/pages/student/join_sala_page.dart';
import '../../presentation/pages/student/select_faculdade_page.dart';
import '../../presentation/pages/driver/driver_shell.dart';
import '../../presentation/pages/driver/create_sala_page.dart';
import '../../presentation/pages/driver/manage_faculdades_page.dart';
import '../../presentation/pages/driver/attendance_overview_page.dart';
import '../../presentation/pages/driver/route_builder_page.dart';
import '../../presentation/pages/driver/active_route_page.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';

class AppRoutes {
  // Shared
  static const String splash = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';

  // Student
  static const String studentShell = '/student';
  static const String joinSala = '/join-sala';
  static const String selectFaculdade = '/select-faculdade';

  // Driver
  static const String driverShell = '/driver';
  static const String createSala = '/create-sala';
  static const String manageFaculdades = '/manage-faculdades';
  static const String attendanceOverview = '/attendance-overview';
  static const String routeBuilder = '/route-builder';
  static const String activeRoute = '/active-route';
}

class AppRouter {
  static late AuthViewModel authViewModel;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.landing:
        return _fade(const LandingPage());
      case AppRoutes.login:
        return _slide(LoginPage(
          nextRoute: settings.arguments as String?,
          viewModel: authViewModel,
        ));
      case AppRoutes.register:
        return _slide(RegisterPage(viewModel: authViewModel));
      case AppRoutes.profile:
        return _slide(ProfilePage(viewModel: authViewModel));

      // Student
      case AppRoutes.studentShell:
        return _fade(StudentShell(viewModel: authViewModel));
      case AppRoutes.joinSala:
        return _slide(JoinSalaPage(viewModel: authViewModel));
      case AppRoutes.selectFaculdade:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slide(SelectFaculdadePage(
          viewModel: authViewModel,
          salaId: args?['salaId'] as String? ?? '',
        ));

      // Driver
      case AppRoutes.driverShell:
        return _fade(DriverShell(viewModel: authViewModel));
      case AppRoutes.createSala:
        return _slide(CreateSalaPage(viewModel: authViewModel));
      case AppRoutes.manageFaculdades:
        return _slide(ManageFaculdadesPage(viewModel: authViewModel));
      case AppRoutes.attendanceOverview:
        return _slide(const AttendanceOverviewPage());
      case AppRoutes.routeBuilder:
        return _slide(const RouteBuilderPage());
      case AppRoutes.activeRoute:
        return _slide(const ActiveRoutePage(), settings: settings);

      case AppRoutes.splash:
      default:
        return _fade(SplashPage(viewModel: authViewModel));
    }
  }

  static PageRouteBuilder _fade(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slide(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
