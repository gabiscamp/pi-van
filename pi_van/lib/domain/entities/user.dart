import '../enums/role_enum.dart';

class User {
  final String id;
  final String name;
  final String email;
  final Role role;
  final String? salaId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.salaId,
  });
}
