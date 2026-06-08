import '../entities/sala.dart';
import '../entities/faculdade.dart';
import '../entities/student_address.dart';

abstract class SalaRepository {
  Future<Sala> createSala({required String name, required String driverId, String? driverName});
  Future<Sala?> joinSala({required String studentId, required String studentName, required String accessCode});
  Future<void> leaveSala({required String studentId, required String salaId});
  Future<Sala?> getSalaById(String salaId);
  Future<List<Sala>> getSalasByDriver(String driverId);
  Future<List<Sala>> getSalasByIds(List<String> ids);

  // Sala CRUD (motorista)
  Future<void> updateSala({required String salaId, required String name});
  Future<void> deleteSala(String salaId);
  Future<List<Map<String, dynamic>>> getStudents(String salaId);
  Future<void> setStudentFaculdade({required String salaId, required String studentId, required String? faculdadeId, required String? faculdadeName});

  // Faculdades
  Future<List<Faculdade>> getFaculdades(String salaId);
  Future<Faculdade> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng});
  Future<void> updateFaculdade({required String salaId, required String faculdadeId, required String name, required String address, required double lat, required double lng});
  Future<void> removeFaculdade({required String salaId, required String faculdadeId});
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId);

  // Endereços do aluno (múltiplos)
  Future<List<StudentAddress>> getAddresses(String userId);
  Future<StudentAddress> addAddress({required String userId, required StudentAddress address});
  Future<void> updateAddress({required String userId, required StudentAddress address});
  Future<void> deleteAddress({required String userId, required String addressId});
  Future<void> setDefaultAddress({required String userId, required String addressId});

  // Attendance
  Future<void> saveVote({required String salaId, required String date, required String userId, required Map<String, dynamic> data});
  Stream<Map<String, dynamic>> attendanceStream({required String salaId, required String date});
  Future<Map<String, dynamic>> getAttendance({required String salaId, required String date});

  // Driver location
  Future<void> updateDriverLocation({required String salaId, required double lat, required double lng, required bool isSharing});
  Stream<Map<String, dynamic>?> driverLocationStream(String salaId);
}
