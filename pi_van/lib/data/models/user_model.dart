import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.salaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'salaId': salaId,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: Role.values.firstWhere(
        (value) => value.name == map['role'],
        orElse: () => Role.estudante,
      ),
      salaId: map['salaId'] as String?,
    );
  }
}
