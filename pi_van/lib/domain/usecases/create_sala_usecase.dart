import '../entities/sala.dart';
import '../repositories/sala_repository.dart';

class CreateSalaUseCase {
  final SalaRepository repository;
  CreateSalaUseCase(this.repository);

  Future<Sala> execute({required String name, required String driverId, String? driverName}) =>
      repository.createSala(name: name, driverId: driverId, driverName: driverName);
}
