import '../entities/sala.dart';
import '../repositories/sala_repository.dart';

class JoinSalaUseCase {
  final SalaRepository repository;
  JoinSalaUseCase(this.repository);

  Future<Sala?> execute({required String studentId, required String studentName, required String accessCode}) =>
      repository.joinSala(studentId: studentId, studentName: studentName, accessCode: accessCode);
}
