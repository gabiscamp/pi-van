import 'package:pi_van/domain/enums/role_enum.dart' show Role;
import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id, required super.name, required super.email,
    super.phone = '', required super.role, super.salaId,
    super.salaIds = const [],
    required super.logradouro, required super.numero,
    required super.complemento, required super.bairro,
    required super.cep, required super.localidade, required super.uf,
    super.latitude, super.longitude, super.faculdadeId, super.faculdadeName,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] ?? '', name: j['name'] ?? '', email: j['email'] ?? '',
    phone: j['phone'] ?? '',
    role: Role.values.firstWhere((e) => e.name == j['role'], orElse: () => Role.estudante),
    salaId: j['salaId'],
    salaIds: (j['salaIds'] as List?)?.cast<String>() ?? (j['salaId'] != null ? [j['salaId'] as String] : []),
    logradouro: j['logradouro'] ?? '', numero: j['numero'] ?? '',
    complemento: j['complemento'] ?? '', bairro: j['bairro'] ?? '',
    cep: j['cep'] ?? '', localidade: j['localidade'] ?? '', uf: j['uf'] ?? '',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    faculdadeId: j['faculdadeId'], faculdadeName: j['faculdadeName'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'email': email, 'phone': phone,
    'role': role.name, 'salaId': salaId, 'salaIds': salaIds,
    'logradouro': logradouro, 'numero': numero, 'complemento': complemento,
    'bairro': bairro, 'cep': cep, 'localidade': localidade, 'uf': uf,
    'latitude': latitude, 'longitude': longitude,
    'faculdadeId': faculdadeId, 'faculdadeName': faculdadeName,
  };
}
