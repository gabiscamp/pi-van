import '../models/user_model.dart';
import '../../domain/enums/role_enum.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required Role role,
  });

  Future<void> logout();
}
