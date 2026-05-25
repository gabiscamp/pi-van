import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pi_van/domain/enums/role_enum.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSource({required this.firebaseAuth, required this.firestore});

  Future<UserModel> registerUser({
    required String name, required String email, required String password,
    required Role role, required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Falha ao criar usuário no Firebase.');

      final userModel = UserModel(
        id: firebaseUser.uid, name: name, email: email, role: role,
        logradouro: logradouro, numero: numero, complemento: complemento,
        bairro: bairro, cep: cep, localidade: localidade, uf: uf,
        latitude: latitude, longitude: longitude,
      );
      await firestore.collection('users').doc(firebaseUser.uid).set(userModel.toJson());
      return userModel;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw Exception('A senha fornecida é muito fraca.');
      if (e.code == 'email-already-in-use') throw Exception('A conta já existe para esse e-mail.');
      throw Exception(e.message ?? 'Erro desconhecido ao cadastrar.');
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
      email: email, password: password,
    );
    final doc = await firestore.collection('users').doc(userCredential.user!.uid).get();
    if (!doc.exists) throw Exception('Usuário não encontrado no banco de dados.');
    return UserModel.fromJson(doc.data()!);
  }

  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    final doc = await firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUser(UserModel user) async {
    await firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
  }
}
