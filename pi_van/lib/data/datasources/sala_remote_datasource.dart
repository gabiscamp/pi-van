import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sala_model.dart';
import '../models/faculdade_model.dart';

abstract class SalaRemoteDataSource {
  Future<SalaModel> createSala({required String name, required String driverId, String? driverName});
  Future<SalaModel?> joinSala({required String studentId, required String studentName, required String accessCode});
  Future<SalaModel?> getSalaById(String salaId);
  Future<List<FaculdadeModel>> getFaculdades(String salaId);
  Future<FaculdadeModel> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng});
  Future<void> removeFaculdade({required String salaId, required String faculdadeId});
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId);
}

class SalaRemoteDataSourceImpl implements SalaRemoteDataSource {
  final FirebaseFirestore firestore;
  final Uuid uuid;

  SalaRemoteDataSourceImpl({required this.firestore, required this.uuid});

  @override
  Future<SalaModel> createSala({required String name, required String driverId, String? driverName}) async {
    final id = uuid.v4();
    final accessCode = uuid.v4().substring(0, 6).toUpperCase();
    final sala = SalaModel(id: id, name: name, accessCode: accessCode, driverId: driverId, driverName: driverName);
    await firestore.collection('salas').doc(id).set(sala.toMap());
    return sala;
  }

  @override
  Future<SalaModel?> joinSala({required String studentId, required String studentName, required String accessCode}) async {
    final query = await firestore.collection('salas').where('accessCode', isEqualTo: accessCode).get();
    if (query.docs.isEmpty) return null;

    final salaDoc = query.docs.first;
    final sala = SalaModel.fromMap(salaDoc.data());

    // Adiciona o aluno na subcoleção students da sala
    await firestore.collection('salas').doc(sala.id).collection('students').doc(studentId).set({
      'userId': studentId,
      'name': studentName,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Atualiza o salaId no documento do usuário
    await firestore.collection('users').doc(studentId).update({'salaId': sala.id});

    return sala;
  }

  @override
  Future<SalaModel?> getSalaById(String salaId) async {
    final doc = await firestore.collection('salas').doc(salaId).get();
    if (doc.exists) return SalaModel.fromMap(doc.data()!);
    return null;
  }

  @override
  Future<List<FaculdadeModel>> getFaculdades(String salaId) async {
    final snap = await firestore.collection('salas').doc(salaId).collection('faculdades').get();
    return snap.docs.map((d) => FaculdadeModel.fromMap(d.data())).toList();
  }

  @override
  Future<FaculdadeModel> addFaculdade({required String salaId, required String name, required String address, required double lat, required double lng}) async {
    final id = uuid.v4();
    final fac = FaculdadeModel(id: id, name: name, address: address, latitude: lat, longitude: lng);
    await firestore.collection('salas').doc(salaId).collection('faculdades').doc(id).set(fac.toMap());
    return fac;
  }

  @override
  Future<void> removeFaculdade({required String salaId, required String faculdadeId}) async {
    await firestore.collection('salas').doc(salaId).collection('faculdades').doc(faculdadeId).delete();
  }

  @override
  Stream<List<Map<String, dynamic>>> studentsStream(String salaId) {
    return firestore.collection('salas').doc(salaId).collection('students').snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }
}
