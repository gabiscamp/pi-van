import '../../domain/entities/sala.dart';
import '../../domain/entities/faculdade.dart';
import '../../domain/entities/student_address.dart';
import '../../domain/repositories/sala_repository.dart';
import '../datasources/sala_remote_datasource.dart';

class FirebaseSalaRepository implements SalaRepository {
  final SalaRemoteDataSourceImpl ds;
  FirebaseSalaRepository(this.ds);

  @override Future<Sala> createSala({required String name, required String driverId, String? driverName}) =>
    ds.createSala(name: name, driverId: driverId, driverName: driverName);
  @override Future<Sala?> joinSala({required String studentId, required String studentName, required String accessCode}) =>
    ds.joinSala(studentId: studentId, studentName: studentName, accessCode: accessCode);
  @override Future<void> leaveSala({required String studentId, required String salaId}) =>
    ds.leaveSala(studentId: studentId, salaId: salaId);
  @override Future<Sala?> getSalaById(String salaId) => ds.getSalaById(salaId);
  @override Future<List<Sala>> getSalasByDriver(String driverId) => ds.getSalasByDriver(driverId);
  @override Future<List<Sala>> getSalasByIds(List<String> ids) => ds.getSalasByIds(ids);

  @override Future<void> updateSala({required String salaId, required String name}) =>
    ds.updateSala(salaId: salaId, name: name);
  @override Future<void> deleteSala(String salaId) => ds.deleteSala(salaId);
  @override Future<List<Map<String, dynamic>>> getStudents(String salaId) => ds.getStudents(salaId);
  @override Future<void> setStudentFaculdade({required String salaId, required String studentId, required String? faculdadeId, required String? faculdadeName}) =>
    ds.setStudentFaculdade(salaId: salaId, studentId: studentId, faculdadeId: faculdadeId, faculdadeName: faculdadeName);

  @override Future<List<Faculdade>> getFaculdades(String salaId) => ds.getFaculdades(salaId);
  @override Future<Faculdade> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng}) =>
    ds.addFaculdade(salaId: salaId, name: name, address: address, lat: lat, lng: lng);
  @override Future<void> updateFaculdade({required String salaId, required String faculdadeId, required String name, required String address, required double lat, required double lng}) =>
    ds.updateFaculdade(salaId: salaId, faculdadeId: faculdadeId, name: name, address: address, lat: lat, lng: lng);
  @override Future<void> removeFaculdade({required String salaId, required String faculdadeId}) =>
    ds.removeFaculdade(salaId: salaId, faculdadeId: faculdadeId);
  @override Stream<List<Map<String, dynamic>>> studentsStream(String salaId) => ds.studentsStream(salaId);

  // ===== Endereços =====
  @override Future<List<StudentAddress>> getAddresses(String userId) async => ds.getAddresses(userId);
  @override Future<StudentAddress> addAddress({required String userId, required StudentAddress address}) =>
    ds.addAddress(userId: userId, address: address);
  @override Future<void> updateAddress({required String userId, required StudentAddress address}) =>
    ds.updateAddress(userId: userId, address: address);
  @override Future<void> deleteAddress({required String userId, required String addressId}) =>
    ds.deleteAddress(userId: userId, addressId: addressId);
  @override Future<void> setDefaultAddress({required String userId, required String addressId}) =>
    ds.setDefaultAddress(userId: userId, addressId: addressId);

  // ===== Attendance =====
  @override Future<void> saveVote({required String salaId, required String date, required String userId, required Map<String, dynamic> data}) =>
    ds.saveVote(salaId: salaId, date: date, userId: userId, data: data);
  @override Stream<Map<String, dynamic>> attendanceStream({required String salaId, required String date}) =>
    ds.attendanceStream(salaId: salaId, date: date);
  @override Future<Map<String, dynamic>> getAttendance({required String salaId, required String date}) =>
    ds.getAttendance(salaId: salaId, date: date);

  // ===== Driver location =====
  @override Future<void> updateDriverLocation({required String salaId, required double lat, required double lng, required bool isSharing}) =>
    ds.updateDriverLocation(salaId: salaId, lat: lat, lng: lng, isSharing: isSharing);
  @override Stream<Map<String, dynamic>?> driverLocationStream(String salaId) => ds.driverLocationStream(salaId);
}
