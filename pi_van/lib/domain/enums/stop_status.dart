/// Status de cada parada durante a execução da rota pelo motorista.
enum StopStatus {
  aguardando,
  emAndamento,
  concluida,
  ausente,
  cancelada,
}

extension StopStatusExt on StopStatus {
  String get label {
    switch (this) {
      case StopStatus.aguardando:
        return 'Aguardando';
      case StopStatus.emAndamento:
        return 'Em andamento';
      case StopStatus.concluida:
        return 'Concluída';
      case StopStatus.ausente:
        return 'Ausente';
      case StopStatus.cancelada:
        return 'Cancelada';
    }
  }

  /// Indica se a parada já saiu da fila de paradas pendentes.
  bool get isResolved =>
      this == StopStatus.concluida ||
      this == StopStatus.ausente ||
      this == StopStatus.cancelada;
}
