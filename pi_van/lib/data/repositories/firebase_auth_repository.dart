import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthRemoteDataSource ds;
  FirebaseAuthRepository(this.ds);

  @override
  Future<User> login({required String email, required String password}) => ds.login(email: email, password: password);

  @override
  Future<User> register({
    required String name, required String email, required String password,
    required String phone, required Role role,
    required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) => ds.registerUser(
    name: name, email: email, password: password, phone: phone, role: role,
    logradouro: logradouro, numero: numero, complemento: complemento,
    bairro: bairro, cep: cep, localidade: localidade, uf: uf,
    latitude: latitude, longitude: longitude,
  );

  @override
  Future<User?> getCurrentUser() => ds.getCurrentUser();

  @override
  Future<void> updateUser(User u) => ds.updateUser(UserModel(
    id: u.id, name: u.name, email: u.email, phone: u.phone, role: u.role,
    salaId: u.salaId, salaIds: u.salaIds,
    logradouro: u.logradouro, numero: u.numero, complemento: u.complemento,
    bairro: u.bairro, cep: u.cep, localidade: u.localidade, uf: u.uf,
    latitude: u.latitude, longitude: u.longitude,
    faculdadeId: u.faculdadeId, faculdadeName: u.faculdadeName,
  ));

  @override
  Future<void> logout() => ds.logout();

  @override
  Future<void> sendPasswordResetEmail(String email) => ds.sendPasswordResetEmail(email);
}
