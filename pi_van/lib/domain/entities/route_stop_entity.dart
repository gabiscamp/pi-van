import '../enums/stop_status.dart';

/// Tipo de parada na rota.
enum RouteStopKind {
  /// Embarque de um aluno (rota de ida, em casa/endereço escolhido).
  embarqueAluno,

  /// Desembarque de um aluno (rota de volta, em casa/endereço escolhido).
  desembarqueAluno,

  /// Faculdade: ponto de desembarque (ida) ou embarque (volta) de vários alunos.
  faculdade,
}

/// Representa um aluno associado a uma parada de faculdade
/// (para exibir "quem desembarca/embarca aqui").
class StopPassenger {
  final String userId;
  final String name;
  final String? faculdadeName;

  const StopPassenger({
    required this.userId,
    required this.name,
    this.faculdadeName,
  });
}

/// Uma parada da rota. Imutável exceto pelo [status], que muda durante a
/// execução; por isso [copyWith] existe para gerar uma nova instância.
class RouteStopEntity {
  final String id;
  final RouteStopKind kind;

  /// Nome principal exibido (aluno ou faculdade).
  final String name;

  /// Endereço curto exibido.
  final String address;

  final double latitude;
  final double longitude;

  /// Para paradas de aluno: faculdade de destino/origem do aluno.
  final String? faculdadeName;

  /// Rótulo do endereço escolhido (ex: "Casa", "Trabalho", "República").
  final String? addressLabel;

  /// Para paradas de faculdade: alunos que desembarcam (ida) ou embarcam (volta).
  final List<StopPassenger> passengers;

  final StopStatus status;

  const RouteStopEntity({
    required this.id,
    required this.kind,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.faculdadeName,
    this.addressLabel,
    this.passengers = const [],
    this.status = StopStatus.aguardando,
  });

  bool get isFaculdade => kind == RouteStopKind.faculdade;
  bool get isPickup => kind == RouteStopKind.embarqueAluno;
  bool get isDropoff => kind == RouteStopKind.desembarqueAluno;

  bool get hasCoordinates =>
      !(latitude == 0 && longitude == 0);

  /// Quantos alunos esta parada movimenta (1 para aluno, N para faculdade).
  int get passengerCount => isFaculdade ? passengers.length : 1;

  RouteStopEntity copyWith({StopStatus? status, List<StopPassenger>? passengers}) => RouteStopEntity(
        id: id,
        kind: kind,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        faculdadeName: faculdadeName,
        addressLabel: addressLabel,
        passengers: passengers ?? this.passengers,
        status: status ?? this.status,
      );
}
