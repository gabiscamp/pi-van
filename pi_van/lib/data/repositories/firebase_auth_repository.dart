import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  FirebaseAuthRepository(this.remoteDataSource);

  @override
  Future<User> login({required String email, required String password}) {
    return remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  }) {
    return remoteDataSource.registerUser(
      name: name,
      email: email,
      password: password,
      role: role,
    );
  }

  @override
  Future<void> logout() {
    return remoteDataSource.logout();
  }
}
