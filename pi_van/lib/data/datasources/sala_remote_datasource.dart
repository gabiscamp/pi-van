import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sala_model.dart';
import '../models/faculdade_model.dart';

class SalaRemoteDataSourceImpl {
  final FirebaseFirestore firestore;
  final Uuid uuid;
  SalaRemoteDataSourceImpl({required this.firestore, required this.uuid});

  Future<SalaModel> createSala({required String name, required String driverId, String? driverName}) async {
    final id = uuid.v4();
    final code = uuid.v4().substring(0, 6).toUpperCase();
    final sala = SalaModel(id: id, name: name, accessCode: code, driverId: driverId, driverName: driverName);
    await firestore.collection('salas').doc(id).set(sala.toMap());
    return sala;
  }

  Future<SalaModel?> joinSala({required String studentId, required String studentName, required String accessCode}) async {
    final query = await firestore.collection('salas').where('accessCode', isEqualTo: accessCode).get();
    if (query.docs.isEmpty) return null;
    final sala = SalaModel.fromMap(query.docs.first.data());

    await firestore.collection('salas').doc(sala.id).collection('students').doc(studentId).set({
      'userId': studentId, 'name': studentName, 'joinedAt': FieldValue.serverTimestamp(),
    });

    // Adiciona salaId na lista do user
    await firestore.collection('users').doc(studentId).update({
      'salaId': sala.id,
      'salaIds': FieldValue.arrayUnion([sala.id]),
    });
    return sala;
  }

  Future<void> leaveSala({required String studentId, required String salaId}) async {
    await firestore.collection('salas').doc(salaId).collection('students').doc(studentId).delete();
    await firestore.collection('users').doc(studentId).update({
      'salaIds': FieldValue.arrayRemove([salaId]),
    });
  }

  Future<SalaModel?> getSalaById(String salaId) async {
    final doc = await firestore.collection('salas').doc(salaId).get();
    return doc.exists ? SalaModel.fromMap(doc.data()!) : null;
  }

  Future<List<SalaModel>> getSalasByDriver(String driverId) async {
    final snap = await firestore.collection('salas').where('driverId', isEqualTo: driverId).get();
    return snap.docs.map((d) => SalaModel.fromMap(d.data())).toList();
  }

  Future<List<FaculdadeModel>> getFaculdades(String salaId) async {
    final snap = await firestore.collection('salas').doc(salaId).collection('faculdades').get();
    return snap.docs.map((d) => FaculdadeModel.fromMap(d.data())).toList();
  }

  Future<FaculdadeModel> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng}) async {
    final id = uuid.v4();
    final fac = FaculdadeModel(id: id, name: name, address: address, latitude: lat, longitude: lng);
    await firestore.collection('salas').doc(salaId).collection('faculdades').doc(id).set(fac.toMap());
    return fac;
  }

  Future<void> removeFaculdade({required String salaId, required String faculdadeId}) async {
    await firestore.collection('salas').doc(salaId).collection('faculdades').doc(faculdadeId).delete();

    // Limpar faculdadeId dos alunos desta sala que tinham essa faculdade
    try {
      final studentsSnap = await firestore.collection('salas').doc(salaId).collection('students').get();
      if (studentsSnap.docs.isEmpty) return;
      final userIds = studentsSnap.docs
          .map((d) => d.data()['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final userDocs = await Future.wait(userIds.map((id) => firestore.collection('users').doc(id).get()));
      final batch = firestore.batch();
      for (final doc in userDocs) {
        if (doc.exists && doc.data()?['faculdadeId'] == faculdadeId) {
          batch.update(doc.reference, {'faculdadeId': null, 'faculdadeName': null});
        }
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<List<SalaModel>> getSalasByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(ids.map((id) => firestore.collection('salas').doc(id).get()));
    return docs.where((d) => d.exists).map((d) => SalaModel.fromMap(d.data()!)).toList();
  }

  Stream<List<Map<String, dynamic>>> studentsStream(String salaId) {
    return firestore.collection('salas').doc(salaId).collection('students').snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  // ===== ATTENDANCE =====
  Future<void> saveVote({required String salaId, required String date, required String userId, required Map<String, dynamic> data}) async {
    await firestore.collection('salas').doc(salaId).collection('attendance').doc(date).collection('votes').doc(userId).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> attendanceStream({required String salaId, required String date}) {
    return firestore.collection('salas').doc(salaId).collection('attendance').doc(date).collection('votes').snapshots().map((snap) {
      final map = <String, dynamic>{};
      for (final doc in snap.docs) { map[doc.id] = doc.data(); }
      return map;
    });
  }

  // ===== DRIVER LOCATION =====
  Future<void> updateDriverLocation({required String salaId, required double lat, required double lng, required bool isSharing}) async {
    await firestore.collection('salas').doc(salaId).collection('driverLocation').doc('current').set({
      'latitude': lat, 'longitude': lng, 'isSharing': isSharing, 'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> driverLocationStream(String salaId) {
    return firestore.collection('salas').doc(salaId).collection('driverLocation').doc('current').snapshots().map(
      (snap) => snap.exists ? snap.data() : null,
    );
  }
}
