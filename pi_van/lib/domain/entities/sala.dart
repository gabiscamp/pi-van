class Sala {
  final String id;
  final String name;
  final String accessCode;
  final String driverId;
  final String? driverName;

  const Sala({
    required this.id,
    required this.name,
    required this.accessCode,
    required this.driverId,
    this.driverName,
  });

  Sala copyWith({
    String? id,
    String? name,
    String? accessCode,
    String? driverId,
    String? driverName,
  }) =>
      Sala(
        id: id ?? this.id,
        name: name ?? this.name,
        accessCode: accessCode ?? this.accessCode,
        driverId: driverId ?? this.driverId,
        driverName: driverName ?? this.driverName,
      );
}
