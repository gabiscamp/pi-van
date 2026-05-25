import '../entities/user.dart';
import '../enums/role_enum.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<User> execute({
    required String name, required String email, required String password,
    required Role role, required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) => repository.register(
    name: name, email: email, password: password, role: role,
    logradouro: logradouro, numero: numero, complemento: complemento,
    bairro: bairro, cep: cep, localidade: localidade, uf: uf,
    latitude: latitude, longitude: longitude,
  );
}
