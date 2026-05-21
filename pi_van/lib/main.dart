// lib/main.dart
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';

import 'package:pi_van/data/repositories/firebase_auth_repository.dart';
import 'package:pi_van/domain/usecases/login_usecase.dart';
import 'package:pi_van/domain/usecases/register_usecase.dart';
import 'package:pi_van/presentation/viewmodels/auth_viewmodel.dart';


import 'core/routing/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'core/di/service_locator.dart';


void main() async {
  // Garante que o Flutter está pronto antes de iniciar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando com as chaves que você pegou do console
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup service locator
  ServiceLocator.setup();
  

  // Roda o seu app
  runApp(const MeuAppVans());
}

class MeuAppVans extends StatelessWidget {
  const MeuAppVans({super.key});

  @override
  Widget build(BuildContext context) {
    // Get dependencies from service locator
    final repository = ServiceLocator.getIt<FirebaseAuthRepository>();
    final loginUseCase = LoginUseCase(repository);
    final registerUseCase = RegisterUseCase(repository);

    // Passa os dois para o ViewModel correto
    final viewModel = AuthViewModel(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
    );
    AppRouter.authViewModel = viewModel;
    // ---------------------------------------

    return MaterialApp(

      title: 'PI Van',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRouter.onGenerateRoute,

    );
  }
}
