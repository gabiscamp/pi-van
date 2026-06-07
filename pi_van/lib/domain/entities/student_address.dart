/// Um endereço cadastrado por um aluno. Um aluno pode ter vários
/// (casa, trabalho, casa de familiar, república estudantil, etc.).
class StudentAddress {
  final String id;

  /// Rótulo amigável escolhido pelo aluno. Ex: "Casa", "Trabalho".
  final String label;

  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cep;
  final String localidade;
  final String uf;

  final double? latitude;
  final double? longitude;

  /// Endereço usado por padrão quando o aluno não escolher outro.
  final bool isDefault;

  const StudentAddress({
    required this.id,
    required this.label,
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.cep = '',
    this.localidade = '',
    this.uf = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);

  String get enderecoCompleto {
    final parts = <String>[
      if (logradouro.isNotEmpty) logradouro,
      if (numero.isNotEmpty) numero,
      if (complemento.isNotEmpty) complemento,
      if (bairro.isNotEmpty) bairro,
      if (localidade.isNotEmpty) localidade,
      if (uf.isNotEmpty) uf,
    ];
    return parts.join(', ');
  }

  /// Versão curta para exibição em listas/rotas.
  String get enderecoCurto {
    final parts = <String>[
      if (logradouro.isNotEmpty) logradouro,
      if (numero.isNotEmpty) numero,
    ];
    if (parts.isEmpty && bairro.isNotEmpty) parts.add(bairro);
    return parts.join(', ');
  }

  StudentAddress copyWith({
    String? id,
    String? label,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cep,
    String? localidade,
    String? uf,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      StudentAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        logradouro: logradouro ?? this.logradouro,
        numero: numero ?? this.numero,
        complemento: complemento ?? this.complemento,
        bairro: bairro ?? this.bairro,
        cep: cep ?? this.cep,
        localidade: localidade ?? this.localidade,
        uf: uf ?? this.uf,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
      );
}
