import 'package:pi_van/domain/enums/role_enum.dart';

import '../../domain/entities/user.dart';


class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.salaId,
    required super.logradouro,
    required super.numero,
    required super.complemento,
    required super.bairro,
    required super.cep,
    required super.localidade,
    required super.uf,
  });

  // ESTE É O BLOCO QUE DEVE ESTAR FALTANDO OU COM ERRO:
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: Role.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => Role.estudante,
      ),
      salaId: json['salaId'],
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      cep: json['cep'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'salaId': salaId,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cep': cep,
      'localidade': localidade,
      'uf': uf,
    };
  }
}