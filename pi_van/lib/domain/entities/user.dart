import '../enums/role_enum.dart';

class User {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? salaId;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cep;
  final String localidade;
  final String uf;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.salaId,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cep,
    required this.localidade,
    required this.uf,
  });
}
