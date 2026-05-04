import '../../domain/entities/sala.dart';
import '../../domain/repositories/sala_repository.dart';
import '../datasources/sala_remote_datasource.dart';

class FirebaseSalaRepository implements SalaRepository {
  final SalaRemoteDataSource remoteDataSource;

  FirebaseSalaRepository(this.remoteDataSource);

  @override
  Future<Sala> createSala({
    required String name,
    required String driverId,
  }) {
    return remoteDataSource.createSala(name: name, driverId: driverId);
  }

  @override
  Future<bool> joinSala({
    required String studentId,
    required String accessCode,
  }) {
    return remoteDataSource.joinSala(
      studentId: studentId,
      accessCode: accessCode,
    );
  }

  @override
  Future<Sala?> getSalaById(String salaId) {
    return remoteDataSource.getSalaById(salaId);
  }
}
