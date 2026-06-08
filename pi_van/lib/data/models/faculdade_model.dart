import '../../domain/entities/faculdade.dart';

class FaculdadeModel extends Faculdade {
  const FaculdadeModel({
    required super.id, required super.name,
    required super.address, required super.latitude, required super.longitude,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'address': address,
    'latitude': latitude, 'longitude': longitude,
  };

  static FaculdadeModel fromMap(Map<String, dynamic> map) => FaculdadeModel(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    address: map['address'] as String? ?? '',
    latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
  );
}
