import '../../domain/entities/student_address.dart';

class StudentAddressModel extends StudentAddress {
  const StudentAddressModel({
    required super.id,
    required super.label,
    super.logradouro,
    super.numero,
    super.complemento,
    super.bairro,
    super.cep,
    super.localidade,
    super.uf,
    super.latitude,
    super.longitude,
    super.isDefault,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cep': cep,
        'localidade': localidade,
        'uf': uf,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  static StudentAddressModel fromMap(Map<String, dynamic> map) =>
      StudentAddressModel(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? 'Endereço',
        logradouro: map['logradouro'] as String? ?? '',
        numero: map['numero'] as String? ?? '',
        complemento: map['complemento'] as String? ?? '',
        bairro: map['bairro'] as String? ?? '',
        cep: map['cep'] as String? ?? '',
        localidade: map['localidade'] as String? ?? '',
        uf: map['uf'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        isDefault: map['isDefault'] == true,
      );

  factory StudentAddressModel.fromEntity(StudentAddress a) =>
      StudentAddressModel(
        id: a.id,
        label: a.label,
        logradouro: a.logradouro,
        numero: a.numero,
        complemento: a.complemento,
        bairro: a.bairro,
        cep: a.cep,
        localidade: a.localidade,
        uf: a.uf,
        latitude: a.latitude,
        longitude: a.longitude,
        isDefault: a.isDefault,
      );
}
