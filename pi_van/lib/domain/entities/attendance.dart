import '../enums/attendance_status.dart';

class AttendanceVote {
  final String userId;
  final String userName;
  final AttendanceStatus status;
  final bool liberado;
  final DateTime? liberadoAt;
  final String? faculdadeId;
  final String? faculdadeName;

  const AttendanceVote({
    required this.userId,
    required this.userName,
    required this.status,
    this.liberado = false,
    this.liberadoAt,
    this.faculdadeId,
    this.faculdadeName,
  });
}

class DailyAttendance {
  final String date;
  final Map<String, AttendanceVote> votes;

  const DailyAttendance({ required this.date, required this.votes });

  int get totalConfirmed => votes.values
      .where((v) => v.status != AttendanceStatus.naoVai && v.status != AttendanceStatus.pendente)
      .length;
  int get totalLiberados => votes.values.where((v) => v.liberado).length;
  int get totalNaoVai => votes.values.where((v) => v.status == AttendanceStatus.naoVai).length;
  int get totalPendentes => votes.values.where((v) => v.status == AttendanceStatus.pendente).length;

  List<AttendanceVote> get idaStudents => votes.values
      .where((v) => v.status == AttendanceStatus.vaiEVolta || v.status == AttendanceStatus.soIda)
      .toList();
  List<AttendanceVote> get voltaStudents => votes.values
      .where((v) => v.status == AttendanceStatus.vaiEVolta || v.status == AttendanceStatus.soVolta)
      .toList();
}
