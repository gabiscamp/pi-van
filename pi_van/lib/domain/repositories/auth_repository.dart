import '../entities/user.dart';
import '../enums/role_enum.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  Future<User> register( {
    required String name,
    required String email,
    required String password,
    required Role role,
    required String logradouro,
    required String numero,
    required String complemento,
    required String bairro,
    required String cep,
    required String localidade, required String uf,
  });

  Future<void> logout();
  
}
