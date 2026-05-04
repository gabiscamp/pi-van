import '../entities/sala.dart';

abstract class SalaRepository {
  Future<Sala> createSala({
    required String name,
    required String driverId,
  });

  Future<bool> joinSala({
    required String studentId,
    required String accessCode,
  });

  Future<Sala?> getSalaById(String salaId);
}
