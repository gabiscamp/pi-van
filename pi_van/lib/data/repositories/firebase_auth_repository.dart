import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  FirebaseAuthRepository(this.remoteDataSource);

  @override
  Future<User> login({required String email, required String password}) =>
      remoteDataSource.login(email: email, password: password);

  @override
  Future<User> register({
    required String name, required String email, required String password,
    required Role role, required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) => remoteDataSource.registerUser(
    name: name, email: email, password: password, role: role,
    logradouro: logradouro, numero: numero, complemento: complemento,
    bairro: bairro, cep: cep, localidade: localidade, uf: uf,
    latitude: latitude, longitude: longitude,
  );

  @override
  Future<User?> getCurrentUser() => remoteDataSource.getCurrentUser();

  @override
  Future<void> updateUser(User user) => remoteDataSource.updateUser(
    UserModel(
      id: user.id, name: user.name, email: user.email, role: user.role,
      salaId: user.salaId, logradouro: user.logradouro, numero: user.numero,
      complemento: user.complemento, bairro: user.bairro, cep: user.cep,
      localidade: user.localidade, uf: user.uf, latitude: user.latitude,
      longitude: user.longitude, faculdadeId: user.faculdadeId,
      faculdadeName: user.faculdadeName,
    ),
  );

  @override
  Future<void> logout() => remoteDataSource.logout();
}
