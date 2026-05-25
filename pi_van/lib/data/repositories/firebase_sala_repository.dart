import '../../domain/entities/sala.dart';
import '../../domain/entities/faculdade.dart';
import '../../domain/repositories/sala_repository.dart';
import '../datasources/sala_remote_datasource.dart';

class FirebaseSalaRepository implements SalaRepository {
  final SalaRemoteDataSource remoteDataSource;
  FirebaseSalaRepository(this.remoteDataSource);

  @override
  Future<Sala> createSala({required String name, required String driverId, String? driverName}) =>
      remoteDataSource.createSala(name: name, driverId: driverId, driverName: driverName);

  @override
  Future<Sala?> joinSala({required String studentId, required String studentName, required String accessCode}) =>
      remoteDataSource.joinSala(studentId: studentId, studentName: studentName, accessCode: accessCode);

  @override
  Future<Sala?> getSalaById(String salaId) => remoteDataSource.getSalaById(salaId);

  @override
  Future<List<Faculdade>> getFaculdades(String salaId) => remoteDataSource.getFaculdades(salaId);

  @override
  Future<Faculdade> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng}) =>
      remoteDataSource.addFaculdade(salaId: salaId, name: name, address: address, lat: lat, lng: lng);

  @override
  Future<void> removeFaculdade({required String salaId, required String faculdadeId}) =>
      remoteDataSource.removeFaculdade(salaId: salaId, faculdadeId: faculdadeId);

  @override
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId) =>
      remoteDataSource.studentsStream(salaId);
}
