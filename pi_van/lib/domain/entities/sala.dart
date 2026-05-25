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
}
