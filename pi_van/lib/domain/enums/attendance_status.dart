enum AttendanceStatus {
  pendente,
  vaiEVolta,
  soIda,
  soVolta,
  naoVai,
}

extension AttendanceStatusExt on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.pendente: return 'Pendente';
      case AttendanceStatus.vaiEVolta: return 'Ida e Volta';
      case AttendanceStatus.soIda: return 'Só Ida';
      case AttendanceStatus.soVolta: return 'Só Volta';
      case AttendanceStatus.naoVai: return 'Não vai';
    }
  }
}
