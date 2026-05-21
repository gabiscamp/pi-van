import '../models/sala_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

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

class SalaRemoteDataSourceImpl implements SalaRemoteDataSource {
  final FirebaseFirestore firestore;
  final Uuid uuid;

  SalaRemoteDataSourceImpl({
    required this.firestore,
    required this.uuid,
  });

  @override
  Future<SalaModel> createSala({
    required String name,
    required String driverId,
  }) async {
    final id = uuid.v4();
    final accessCode = uuid.v4().substring(0, 6).toUpperCase(); // Generate a short access code
    final sala = SalaModel(
      id: id,
      name: name,
      accessCode: accessCode,
      driverId: driverId,
    );

    await firestore.collection('salas').doc(id).set(sala.toMap());

    return sala;
  }

  @override
  Future<bool> joinSala({
    required String studentId,
    required String accessCode,
  }) async {
    final query = await firestore
        .collection('salas')
        .where('accessCode', isEqualTo: accessCode)
        .get();

    return query.docs.isNotEmpty;
  }

  @override
  Future<SalaModel?> getSalaById(String salaId) async {
    final doc = await firestore.collection('salas').doc(salaId).get();
    if (doc.exists) {
      return SalaModel.fromMap(doc.data()!);
    }
    return null;
  }
}
