import '../models/sala_model.dart';

abstract class SalaRemoteDataSource {
  Future<SalaModel> createSala({
    required String name,
    required String driverId,
  });

  Future<bool> joinSala({
    required String studentId,
    required String accessCode,
  });

  Future<SalaModel?> getSalaById(String salaId);
}
