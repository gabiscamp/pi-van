import '../../domain/entities/sala.dart';

class SalaModel extends Sala {
  const SalaModel({
    required super.id, required super.name,
    required super.accessCode, required super.driverId, super.driverName,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'accessCode': accessCode,
    'driverId': driverId, 'driverName': driverName,
  };

  static SalaModel fromMap(Map<String, dynamic> map) => SalaModel(
    id: map['id'] as String, name: map['name'] as String,
    accessCode: map['accessCode'] as String, driverId: map['driverId'] as String,
    driverName: map['driverName'] as String?,
  );
}
