import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_van/domain/enums/role_enum.dart';


import '../models/user_model.dart';

class AuthRemoteDataSource {
  // Instâncias reais do Firebase
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSource({required this.firebaseAuth, required this.firestore});

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) async {
    try {
      // 1. Cria a conta de autenticação (Email e Senha)
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Falha ao criar usuário no Firebase.');

      // 2. Monta o modelo com o ID que o Firebase gerou
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: role,
      );

      // 3. Salva os dados extras (Nome e Role) no "Banco de Dados" (Firestore)
      await firestore
          .collection('users') // Nome da tabela
          .doc(firebaseUser.uid) // ID da linha
          .set(userModel.toJson()); // Converte para JSON e salva

      return userModel;
    } on FirebaseAuthException catch (e) {
      // Traduz erros comuns do Firebase
      if (e.code == 'weak-password') {
        throw Exception('A senha fornecida é muito fraca.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('A conta já existe para esse e-mail.');
      }
      throw Exception(e.message ?? 'Erro desconhecido ao cadastrar.');
    }

    
  }
  // --- ADICIONE ISSO DENTRO DA CLASSE AuthRemoteDataSource ---

  // Função para fazer o Login real no Firebase
  Future<UserModel> login({
    required String email, 
    required String password,
  }) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Busca os dados extras (como o Role) que salvamos no Firestore
    final doc = await firestore.collection('users').doc(userCredential.user!.uid).get();
    
    if (!doc.exists) throw Exception('Usuário não encontrado no banco de dados.');

    return UserModel.fromJson(doc.data()!);
  }

  // Função para sair da conta
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}