import '../entities/sala.dart';
import '../entities/faculdade.dart';

abstract class SalaRepository {
  Future<Sala> createSala({required String name, required String driverId, String? driverName});
  Future<Sala?> joinSala({required String studentId, required String studentName, required String accessCode});
  Future<Sala?> getSalaById(String salaId);
  Future<List<Faculdade>> getFaculdades(String salaId);
  Future<Faculdade> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng});
  Future<void> removeFaculdade({required String salaId, required String faculdadeId});
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId);
}
