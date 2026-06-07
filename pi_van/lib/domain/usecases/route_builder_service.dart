import '../entities/attendance.dart';
import '../entities/faculdade.dart';
import '../entities/route_stop_entity.dart';
import '../enums/attendance_status.dart';
import '../enums/route_type.dart';

/// Dados de um aluno necessários para montar uma parada.
/// É o "voto do dia" já resolvido com o endereço escolhido.
class RoutePassengerInput {
  final String userId;
  final String name;
  final AttendanceStatus status;
  final String? faculdadeId;
  final String? faculdadeName;

  /// Endereço de embarque escolhido para o dia (ida).
  final AddressRef? boarding;

  /// Endereço de desembarque escolhido para o dia (volta).
  final AddressRef? dropoff;

  const RoutePassengerInput({
    required this.userId,
    required this.name,
    required this.status,
    this.faculdadeId,
    this.faculdadeName,
    this.boarding,
    this.dropoff,
  });

  bool get vaiIda =>
      status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soIda;
  bool get vaiVolta =>
      status == AttendanceStatus.vaiEVolta ||
      status == AttendanceStatus.soVolta;
}

/// Constrói a lista de paradas de uma rota a partir da chamada do dia.
///
/// Regras implementadas (refletem o funcionamento real da van):
///
/// IDA:
///   1. Primeiro todas as paradas de embarque dos alunos (em casa / endereço
///      escolhido).
///   2. Depois as faculdades de destino.
///   3. Uma faculdade só aparece se houver pelo menos um aluno indo para ela.
///   4. Alunos da mesma faculdade são agrupados em uma única parada de faculdade.
///
/// VOLTA:
///   1. Primeiro as faculdades (origem).
///   2. Depois as paradas de desembarque dos alunos.
///   3. Só aparecem alunos que marcaram volta.
///   4. Só aparecem faculdades que têm alunos voltando.
///
/// Em ambos os casos, alunos ausentes (não vão / pendentes / sem aquele
/// trecho marcado) e endereços não utilizados nunca entram na rota.
class RouteBuilderService {
  /// Monta as paradas. A ordem inicial respeita a prioridade da rota; a
  /// otimização fina (TSP) é aplicada depois, separadamente, por trecho.
  List<RouteStopEntity> buildStops({
    required RouteType type,
    required List<RoutePassengerInput> passengers,
    required List<Faculdade> faculdades,
  }) {
    final facById = {for (final f in faculdades) f.id: f};

    if (type == RouteType.ida) {
      return _buildIda(passengers, facById);
    }
    return _buildVolta(passengers, facById);
  }

  List<RouteStopEntity> _buildIda(
    List<RoutePassengerInput> passengers,
    Map<String, Faculdade> facById,
  ) {
    final pickups = <RouteStopEntity>[];
    // faculdadeId -> alunos que vão para lá
    final facPassengers = <String, List<StopPassenger>>{};

    for (final p in passengers) {
      if (!p.vaiIda) continue;

      final addr = p.boarding;
      // Embarque do aluno (só entra se tiver coordenadas).
      if (addr != null && addr.hasCoordinates) {
        pickups.add(RouteStopEntity(
          id: 'pickup_${p.userId}',
          kind: RouteStopKind.embarqueAluno,
          name: p.name,
          address: addr.shortAddress,
          latitude: addr.latitude!,
          longitude: addr.longitude!,
          faculdadeName: p.faculdadeName,
          addressLabel: addr.label,
        ));
      }

      // Agrupar aluno na sua faculdade de destino.
      final facId = p.faculdadeId;
      if (facId != null && facId.isNotEmpty && facById.containsKey(facId)) {
        facPassengers.putIfAbsent(facId, () => []).add(StopPassenger(
              userId: p.userId,
              name: p.name,
              faculdadeName: p.faculdadeName,
            ));
      }
    }

    // Faculdades só aparecem se tiverem alunos indo para elas.
    final facStops = <RouteStopEntity>[];
    facPassengers.forEach((facId, students) {
      final fac = facById[facId]!;
      if (fac.latitude == 0 && fac.longitude == 0) return;
      facStops.add(RouteStopEntity(
        id: 'fac_${fac.id}',
        kind: RouteStopKind.faculdade,
        name: fac.name,
        address: fac.address,
        latitude: fac.latitude,
        longitude: fac.longitude,
        passengers: students,
      ));
    });

    // Prioridade da ida: buscar todos os alunos, depois entregar nas faculdades.
    return [...pickups, ...facStops];
  }

  List<RouteStopEntity> _buildVolta(
    List<RoutePassengerInput> passengers,
    Map<String, Faculdade> facById,
  ) {
    final dropoffs = <RouteStopEntity>[];
    final facPassengers = <String, List<StopPassenger>>{};

    for (final p in passengers) {
      if (!p.vaiVolta) continue;

      // Faculdade de origem (de onde o aluno será buscado na volta).
      final facId = p.faculdadeId;
      if (facId != null && facId.isNotEmpty && facById.containsKey(facId)) {
        facPassengers.putIfAbsent(facId, () => []).add(StopPassenger(
              userId: p.userId,
              name: p.name,
              faculdadeName: p.faculdadeName,
            ));
      }

      // Desembarque do aluno (casa / endereço escolhido para a volta).
      final addr = p.dropoff;
      if (addr != null && addr.hasCoordinates) {
        dropoffs.add(RouteStopEntity(
          id: 'dropoff_${p.userId}',
          kind: RouteStopKind.desembarqueAluno,
          name: p.name,
          address: addr.shortAddress,
          latitude: addr.latitude!,
          longitude: addr.longitude!,
          faculdadeName: p.faculdadeName,
          addressLabel: addr.label,
        ));
      }
    }

    // Faculdades só aparecem se tiverem alunos voltando delas.
    final facStops = <RouteStopEntity>[];
    facPassengers.forEach((facId, students) {
      final fac = facById[facId]!;
      if (fac.latitude == 0 && fac.longitude == 0) return;
      facStops.add(RouteStopEntity(
        id: 'fac_${fac.id}',
        kind: RouteStopKind.faculdade,
        name: fac.name,
        address: fac.address,
        latitude: fac.latitude,
        longitude: fac.longitude,
        passengers: students,
      ));
    });

    // Prioridade da volta: começar pelas faculdades, depois levar para casa.
    return [...facStops, ...dropoffs];
  }
}
