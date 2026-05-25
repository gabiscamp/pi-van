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
  final double? latitude;
  final double? longitude;
  final String? faculdadeId;
  final String? faculdadeName;

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
    this.latitude,
    this.longitude,
    this.faculdadeId,
    this.faculdadeName,
  });

  String get enderecoCompleto =>
      '$logradouro, $numero${complemento.isNotEmpty ? ' - $complemento' : ''}, $bairro, $localidade - $uf';

  String get primeiroNome => name.split(' ').first;

  User copyWith({
    String? id, String? name, String? email, Role? role,
    String? salaId, String? logradouro, String? numero,
    String? complemento, String? bairro, String? cep,
    String? localidade, String? uf, double? latitude,
    double? longitude, String? faculdadeId, String? faculdadeName,
  }) {
    return User(
      id: id ?? this.id, name: name ?? this.name,
      email: email ?? this.email, role: role ?? this.role,
      salaId: salaId ?? this.salaId, logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero, complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro, cep: cep ?? this.cep,
      localidade: localidade ?? this.localidade, uf: uf ?? this.uf,
      latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
      faculdadeId: faculdadeId ?? this.faculdadeId,
      faculdadeName: faculdadeName ?? this.faculdadeName,
    );
  }
}
