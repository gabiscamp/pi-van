/// Tipo de rota gerada pelo motorista.
///
/// - [ida]: busca os alunos em casa e os leva até as faculdades.
/// - [volta]: parte das faculdades e leva os alunos de volta para casa.
enum RouteType {
  ida,
  volta,
}

extension RouteTypeExt on RouteType {
  String get label {
    switch (this) {
      case RouteType.ida:
        return 'Rota de Ida';
      case RouteType.volta:
        return 'Rota de Volta';
    }
  }

  String get shortLabel {
    switch (this) {
      case RouteType.ida:
        return 'Ida';
      case RouteType.volta:
        return 'Volta';
    }
  }
}
