// lib/main.dart
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pi_van/data/datasources/auth_remote_datasource.dart';
import 'package:pi_van/data/repositories/firebase_auth_repository.dart';
import 'package:pi_van/domain/usecases/login_usecase.dart';
import 'package:pi_van/domain/usecases/register_usecase.dart';
import 'package:pi_van/presentation/pages/register_page.dart';
import 'package:pi_van/presentation/viewmodels/auth_viewmodel.dart';


void main() async {
  // Garante que o Flutter está pronto antes de iniciar o Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando com as chaves que você pegou do console
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  // Roda o seu app
  runApp(const MeuAppVans());
}

class MeuAppVans extends StatelessWidget {
  const MeuAppVans({super.key});

  @override
  Widget build(BuildContext context) {
    // --- INJEÇÃO DE DEPENDÊNCIA MANUAL ---
    // Ligamos as peças de fora para dentro (Clean Architecture)

    // --- INJEÇÃO DE DEPENDÊNCIA MANUAL ---
    final remoteDataSource = AuthRemoteDataSource(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    final repository = FirebaseAuthRepository(remoteDataSource);

    // Instancia os dois casos de uso
    final loginUseCase = LoginUseCase(repository);
    final registerUseCase = RegisterUseCase(repository);

    // Passa os dois para o ViewModel correto
    final viewModel = AuthViewModel(
      loginUseCase: loginUseCase,
      registerUseCase: registerUseCase,
    );
    // ---------------------------------------

    return MaterialApp(
      title: 'App de Van',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RegisterPage(viewModel: viewModel),
    );
  }
}
