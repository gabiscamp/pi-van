import 'package:pi_van/domain/enums/role_enum.dart';

import '../../domain/entities/user.dart';


class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.salaId,
  });

  // ESTE É O BLOCO QUE DEVE ESTAR FALTANDO OU COM ERRO:
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      // Converte a String que vem do banco de volta para o Enum Role
      role: Role.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => Role.estudante,
      ),
      salaId: json['salaId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name, // Salva apenas o nome do enum (ex: "MOTORISTA")
      'salaId': salaId,
    };
  }
}