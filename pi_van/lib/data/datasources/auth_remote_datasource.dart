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
    required String phone, required Role role,
    required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) async {
    try {
      final cred = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = cred.user!.uid;
      final user = UserModel(
        id: uid, name: name, email: email, phone: phone, role: role,
        logradouro: logradouro, numero: numero, complemento: complemento,
        bairro: bairro, cep: cep, localidade: localidade, uf: uf,
        latitude: latitude, longitude: longitude,
      );
      await firestore.collection('users').doc(uid).set(user.toJson());

      // Cria o endereço de casa na subcoleção addresses/ para que o aluno
      // já possa marcar chamada imediatamente após o cadastro.
      if (logradouro.isNotEmpty || bairro.isNotEmpty) {
        final addrRef = firestore.collection('users').doc(uid).collection('addresses').doc();
        await addrRef.set({
          'id': addrRef.id,
          'label': 'Casa',
          'logradouro': logradouro,
          'numero': numero,
          'complemento': complemento,
          'bairro': bairro,
          'cep': cep,
          'localidade': localidade,
          'uf': uf,
          'latitude': latitude,
          'longitude': longitude,
          'isDefault': true,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw Exception('A senha é muito fraca.');
      if (e.code == 'email-already-in-use') throw Exception('E-mail já cadastrado.');
      throw Exception(e.message ?? 'Erro ao cadastrar.');
    }
  }

  Future<UserModel> login({required String email, required String password}) async {
    final cred = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    final doc = await firestore.collection('users').doc(cred.user!.uid).get();
    if (!doc.exists) throw Exception('Usuário não encontrado.');
    return UserModel.fromJson(doc.data()!);
  }

  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    final doc = await firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Future<void> updateUser(UserModel user) async {
    await firestore.collection('users').doc(user.id).update(user.toJson());
  }

  Future<void> logout() async => await firebaseAuth.signOut();

  Future<void> sendPasswordResetEmail(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }
}
