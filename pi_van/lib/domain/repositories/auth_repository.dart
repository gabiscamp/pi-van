import '../entities/user.dart';
import '../enums/role_enum.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  });

  Future<void> logout();
}
