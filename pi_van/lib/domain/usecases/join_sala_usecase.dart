import '../repositories/sala_repository.dart';

class JoinSalaUseCase {
  final SalaRepository repository;

  JoinSalaUseCase(this.repository);

  Future<bool> execute({
    required String studentId,
    required String accessCode,
  }) {
    return repository.joinSala(
      studentId: studentId,
      accessCode: accessCode,
    );
  }
}
