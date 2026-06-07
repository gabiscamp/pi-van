import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sala_model.dart';
import '../models/faculdade_model.dart';
import '../models/student_address_model.dart';
import '../../domain/entities/student_address.dart';

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

  /// Persiste a faculdade do aluno no documento dele dentro da sala, para que
  /// o motorista veja a faculdade mesmo sem o aluno ter feito a chamada do dia.
  Future<void> setStudentFaculdade({
    required String salaId,
    required String studentId,
    required String? faculdadeId,
    required String? faculdadeName,
  }) async {
    await firestore.collection('salas').doc(salaId).collection('students').doc(studentId).set({
      'faculdadeId': faculdadeId,
      'faculdadeName': faculdadeName,
    }, SetOptions(merge: true));
  }

  Future<SalaModel?> getSalaById(String salaId) async {
    final doc = await firestore.collection('salas').doc(salaId).get();
    return doc.exists ? SalaModel.fromMap(doc.data()!) : null;
  }

  Future<List<SalaModel>> getSalasByDriver(String driverId) async {
    final snap = await firestore.collection('salas').where('driverId', isEqualTo: driverId).get();
    return snap.docs.map((d) => SalaModel.fromMap(d.data())).toList();
  }

  Future<void> updateSala({required String salaId, required String name}) async {
    await firestore.collection('salas').doc(salaId).update({'name': name});
  }

  Future<void> deleteSala(String salaId) async {
    // Remove o vínculo dos alunos com a sala antes de excluí-la.
    try {
      final studentsSnap = await firestore.collection('salas').doc(salaId).collection('students').get();
      final userIds = studentsSnap.docs
          .map((d) => d.data()['userId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final batch = firestore.batch();
      for (final id in userIds) {
        final userRef = firestore.collection('users').doc(id);
        batch.update(userRef, {'salaIds': FieldValue.arrayRemove([salaId])});
      }
      // Apaga os docs de alunos da sala.
      for (final doc in studentsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Desativa salaId ativo dos alunos que apontavam para esta sala.
      for (final id in userIds) {
        final userDoc = await firestore.collection('users').doc(id).get();
        if (userDoc.exists && userDoc.data()?['salaId'] == salaId) {
          final remaining = (userDoc.data()?['salaIds'] as List?)?.cast<String>() ?? [];
          await firestore.collection('users').doc(id).update({
            'salaId': remaining.isNotEmpty ? remaining.first : null,
          });
        }
      }
    } catch (_) {}

    // Por fim, remove a sala.
    await firestore.collection('salas').doc(salaId).delete();
  }

  Future<List<Map<String, dynamic>>> getStudents(String salaId) async {
    final snap = await firestore.collection('salas').doc(salaId).collection('students').get();
    return snap.docs.map((d) => d.data()).toList();
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

  // ===== ENDEREÇOS DO ALUNO =====
  CollectionReference<Map<String, dynamic>> _addressesRef(String userId) =>
      firestore.collection('users').doc(userId).collection('addresses');

  Future<List<StudentAddress>> getAddresses(String userId) async {
    final snap = await _addressesRef(userId).get();
    final list = <StudentAddress>[
      for (final d in snap.docs) StudentAddressModel.fromMap(d.data()),
    ];
    // Endereço padrão primeiro, depois por rótulo.
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return list;
  }

  Future<StudentAddressModel> addAddress({required String userId, required StudentAddress address}) async {
    final id = address.id.isNotEmpty ? address.id : uuid.v4();
    // Se for o primeiro endereço, marca como padrão automaticamente.
    final existing = await _addressesRef(userId).get();
    final isFirst = existing.docs.isEmpty;
    var model = StudentAddressModel.fromEntity(address.copyWith(
      id: id,
      isDefault: address.isDefault || isFirst,
    ));

    // Garante apenas um padrão.
    if (model.isDefault) {
      final batch = firestore.batch();
      for (final doc in existing.docs) {
        if (doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      await batch.commit();
    }

    await _addressesRef(userId).doc(id).set(model.toMap());
    return model;
  }

  Future<void> updateAddress({required String userId, required StudentAddress address}) async {
    final model = StudentAddressModel.fromEntity(address);
    await _addressesRef(userId).doc(address.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAddress({required String userId, required String addressId}) async {
    final wasDefaultSnap = await _addressesRef(userId).doc(addressId).get();
    final wasDefault = wasDefaultSnap.data()?['isDefault'] == true;
    await _addressesRef(userId).doc(addressId).delete();

    // Se excluiu o padrão, promove o primeiro restante a padrão.
    if (wasDefault) {
      final remaining = await _addressesRef(userId).get();
      if (remaining.docs.isNotEmpty) {
        await remaining.docs.first.reference.update({'isDefault': true});
      }
    }
  }

  Future<void> setDefaultAddress({required String userId, required String addressId}) async {
    final all = await _addressesRef(userId).get();
    final batch = firestore.batch();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == addressId});
    }
    await batch.commit();
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

  Future<Map<String, dynamic>> getAttendance({required String salaId, required String date}) async {
    final snap = await firestore.collection('salas').doc(salaId).collection('attendance').doc(date).collection('votes').get();
    final map = <String, dynamic>{};
    for (final doc in snap.docs) { map[doc.id] = doc.data(); }
    return map;
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

  // ===== FACULDADE update =====
  Future<void> updateFaculdade({
    required String salaId,
    required String faculdadeId,
    required String name,
    required String address,
    required double lat,
    required double lng,
  }) async {
    await firestore.collection('salas').doc(salaId).collection('faculdades').doc(faculdadeId).update({
      'name': name,
      'address': address,
      'latitude': lat,
      'longitude': lng,
    });
  }
}
