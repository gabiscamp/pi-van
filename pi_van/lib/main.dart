// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Garante que o Flutter está pronto antes de iniciar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializando com as chaves que você pegou do console
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBT6u84CaFJaux2IkhFFQ6OPxsUs_v9X3g",
      authDomain: "app-de-van-5f05d.firebaseapp.com",
      projectId: "app-de-van-5f05d",
      storageBucket: "app-de-van-5f05d.firebasestorage.app",
      messagingSenderId: "688654083193",
      appId: "1:688654083193:web:0e997962cb4ef4beade0a8",
      measurementId: "G-87M58NGN87",
    ),
  );

  // Roda o seu app
  runApp(const MeuAppVans());
}

class MeuAppVans extends StatelessWidget {
  const MeuAppVans({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Van',
      home: Scaffold(
        appBar: AppBar(title: const Text('Início')),
        body: const Center(child: Text('Firebase Conectado!')),
      ),
    );
  }
}