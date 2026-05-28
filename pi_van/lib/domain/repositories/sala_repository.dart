import '../entities/sala.dart';
import '../entities/faculdade.dart';

abstract class SalaRepository {
  Future<Sala> createSala({required String name, required String driverId, String? driverName});
  Future<Sala?> joinSala({required String studentId, required String studentName, required String accessCode});
  Future<void> leaveSala({required String studentId, required String salaId});
  Future<Sala?> getSalaById(String salaId);
  Future<List<Sala>> getSalasByDriver(String driverId);
  Future<List<Sala>> getSalasByIds(List<String> ids);
  Future<List<Faculdade>> getFaculdades(String salaId);
  Future<Faculdade> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng});
  Future<void> removeFaculdade({required String salaId, required String faculdadeId});
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId);
  // Attendance
  Future<void> saveVote({required String salaId, required String date, required String userId, required Map<String, dynamic> data});
  Stream<Map<String, dynamic>> attendanceStream({required String salaId, required String date});
  // Driver location
  Future<void> updateDriverLocation({required String salaId, required double lat, required double lng, required bool isSharing});
  Stream<Map<String, dynamic>?> driverLocationStream(String salaId);
}
