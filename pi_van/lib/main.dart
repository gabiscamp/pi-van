import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pi_van/domain/repositories/auth_repository.dart';
import 'package:pi_van/domain/usecases/login_usecase.dart';
import 'package:pi_van/domain/usecases/register_usecase.dart';
import 'package:pi_van/presentation/viewmodels/auth_viewmodel.dart';

import 'core/routing/app_router.dart';
import 'core/services/notification_service.dart';
import 'presentation/theme/app_theme.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  ServiceLocator.setup();
  await NotificationService.init();

  final authRepository = ServiceLocator.getIt<AuthRepository>();
  final viewModel = AuthViewModel(
    loginUseCase: LoginUseCase(authRepository),
    registerUseCase: RegisterUseCase(authRepository),
    authRepository: authRepository,
  );
  AppRouter.authViewModel = viewModel;

  runApp(MeuAppVans(viewModel: viewModel));
}

class MeuAppVans extends StatelessWidget {
  final AuthViewModel viewModel;
  const MeuAppVans({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
