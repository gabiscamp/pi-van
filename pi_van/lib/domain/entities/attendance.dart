import '../enums/attendance_status.dart';

/// Referência "congelada" a um endereço escolhido pelo aluno para um dia.
///
/// É um snapshot gravado no voto da chamada, de modo que alterações
/// posteriores no cadastro de endereços do aluno não afetem a rota já
/// planejada para aquele dia.
class AddressRef {
  final String addressId;
  final String label; // Ex: "Casa", "Trabalho", "República"
  final String shortAddress; // Texto curto exibido na rota
  final double? latitude;
  final double? longitude;

  const AddressRef({
    required this.addressId,
    required this.label,
    this.shortAddress = '',
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates =>
      latitude != null && longitude != null && !(latitude == 0 && longitude == 0);

  Map<String, dynamic> toMap() => {
        'addressId': addressId,
        'label': label,
        'shortAddress': shortAddress,
        'latitude': latitude,
        'longitude': longitude,
      };

  static AddressRef? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return AddressRef(
      addressId: map['addressId'] as String? ?? '',
      label: map['label'] as String? ?? 'Endereço',
      shortAddress: map['shortAddress'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class AttendanceVote {
  final String userId;
  final String userName;
  final AttendanceStatus status;
  final bool liberado;
  final DateTime? liberadoAt;
  final String? faculdadeId;
  final String? faculdadeName;

  /// Endereço de embarque escolhido para o dia (usado na rota de ida).
  final AddressRef? boarding;

  /// Endereço de desembarque escolhido para o dia (usado na rota de volta).
  final AddressRef? dropoff;

  const AttendanceVote({
    required this.userId,
    required this.userName,
    required this.status,
    this.liberado = false,
    this.liberadoAt,
    this.faculdadeId,
    this.faculdadeName,
    this.boarding,
    this.dropoff,
  });

  bool get vaiNaIda =>
      status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soIda;
  bool get vaiNaVolta =>
      status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soVolta;
  bool get presente =>
      status != AttendanceStatus.naoVai && status != AttendanceStatus.pendente;
}

class DailyAttendance {
  final String date;
  final Map<String, AttendanceVote> votes;

  const DailyAttendance({required this.date, required this.votes});

  int get totalConfirmed => votes.values.where((v) => v.presente).length;
  int get totalLiberados => votes.values.where((v) => v.liberado).length;
  int get totalNaoVai =>
      votes.values.where((v) => v.status == AttendanceStatus.naoVai).length;
  int get totalPendentes =>
      votes.values.where((v) => v.status == AttendanceStatus.pendente).length;

  List<AttendanceVote> get idaStudents =>
      votes.values.where((v) => v.vaiNaIda).toList();
  List<AttendanceVote> get voltaStudents =>
      votes.values.where((v) => v.vaiNaVolta).toList();
}
