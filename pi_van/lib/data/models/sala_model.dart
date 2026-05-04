import '../../domain/entities/sala.dart';

class SalaModel extends Sala {
  const SalaModel({
    required super.id,
    required super.name,
    required super.accessCode,
    required super.driverId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accessCode': accessCode,
      'driverId': driverId,
    };
  }

  static SalaModel fromMap(Map<String, dynamic> map) {
    return SalaModel(
      id: map['id'] as String,
      name: map['name'] as String,
      accessCode: map['accessCode'] as String,
      driverId: map['driverId'] as String,
    );
  }
}
