import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/via_cep_service.dart';
import '../../../domain/entities/student_address.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ManageAddressesPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const ManageAddressesPage({super.key, required this.viewModel});
  @override
  State<ManageAddressesPage> createState() => _ManageAddressesPageState();
}

class _ManageAddressesPageState extends State<ManageAddressesPage> {
  List<StudentAddress> _addresses = [];
  bool _loading = true;

  String get _userId => widget.viewModel.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_userId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await ServiceLocator.getIt<SalaRepository>().getAddresses(_userId);
      if (mounted) setState(() { _addresses = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({StudentAddress? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(userId: _userId, existing: existing),
    );
    if (result == true) _load();
  }

  Future<void> _setDefault(StudentAddress addr) async {
    if (addr.isDefault) return;
    await ServiceLocator.getIt<SalaRepository>().setDefaultAddress(userId: _userId, addressId: addr.id);
    _load();
  }

  Future<void> _delete(StudentAddress addr) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Excluir endereço?'),
      content: Text('Remover "${addr.label}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: AppTheme.error))),
      ],
    ));
    if (ok != true) return;
    await ServiceLocator.getIt<SalaRepository>().deleteAddress(userId: _userId, addressId: addr.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Meus Endereços'), backgroundColor: AppTheme.white, surfaceTintColor: Colors.transparent),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 40)),
                  const SizedBox(height: 20),
                  const Text('Nenhum endereço', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Cadastre seus endereços (casa, trabalho, república...) para usar na chamada.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  AppButton(label: 'Adicionar endereço', icon: Icons.add_rounded, onPressed: () => _openEditor()),
                ])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  itemCount: _addresses.length,
                  itemBuilder: (_, i) => _addressCard(_addresses[i]),
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded), label: const Text('Adicionar'),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd))
          : null,
    );
  }

  Widget _addressCard(StudentAddress a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow,
        border: a.isDefault ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd),
            child: const Icon(Icons.place_rounded, color: AppTheme.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusFull),
                  child: const Text('Padrão', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ]),
            const SizedBox(height: 2),
            Text(a.enderecoCompleto.isNotEmpty ? a.enderecoCompleto : 'Sem endereço detalhado',
              style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (a.hasCoordinates)
              Padding(padding: const EdgeInsets.only(top: 2),
                child: Text('📍 ${a.latitude!.toStringAsFixed(4)}, ${a.longitude!.toStringAsFixed(4)}', style: const TextStyle(color: AppTheme.success, fontSize: 11)))
            else
              const Padding(padding: EdgeInsets.only(top: 2),
                child: Text('⚠ Sem coordenadas (não aparecerá na rota)', style: TextStyle(color: AppTheme.warning, fontSize: 11))),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (!a.isDefault)
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _setDefault(a),
              icon: const Icon(Icons.star_outline_rounded, size: 16),
              label: const Text('Tornar padrão'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
          if (!a.isDefault) const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _openEditor(existing: a),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.grey600,
              side: const BorderSide(color: AppTheme.grey200),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _delete(a),
            icon: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: AppTheme.radiusMd),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18)),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }
}

class _AddressSheet extends StatefulWidget {
  final String userId;
  final StudentAddress? existing;
  const _AddressSheet({required this.userId, this.existing});
  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _cepCtrl;
  late final TextEditingController _ruaCtrl;
  late final TextEditingController _numCtrl;
  late final TextEditingController _compCtrl;
  late final TextEditingController _bairroCtrl;
  late final TextEditingController _cidadeCtrl;
  late final TextEditingController _ufCtrl;
  bool _saving = false;
  String? _geoStatus;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _cepCtrl = TextEditingController(text: e?.cep ?? '');
    _ruaCtrl = TextEditingController(text: e?.logradouro ?? '');
    _numCtrl = TextEditingController(text: e?.numero ?? '');
    _compCtrl = TextEditingController(text: e?.complemento ?? '');
    _bairroCtrl = TextEditingController(text: e?.bairro ?? '');
    _cidadeCtrl = TextEditingController(text: e?.localidade ?? '');
    _ufCtrl = TextEditingController(text: e?.uf ?? '');
  }

  @override
  void dispose() {
    for (final c in [_labelCtrl, _cepCtrl, _ruaCtrl, _numCtrl, _compCtrl, _bairroCtrl, _cidadeCtrl, _ufCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _buscarCep(String cep) async {
    final limpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpo.length != 8) return;
    final data = await ViaCepService().buscarEndereco(limpo);
    if (data != null && mounted) {
      _ruaCtrl.text = data['logradouro'] ?? '';
      _bairroCtrl.text = data['bairro'] ?? '';
      _cidadeCtrl.text = data['localidade'] ?? '';
      _ufCtrl.text = data['uf'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dê um nome ao endereço (ex: Casa)'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() { _saving = true; _geoStatus = 'Localizando endereço...'; });

    final rua = _ruaCtrl.text.trim();
    final num = _numCtrl.text.trim();
    final bairro = _bairroCtrl.text.trim();
    final cidade = _cidadeCtrl.text.trim();
    final uf = _ufCtrl.text.trim();

    double? lat = widget.existing?.latitude;
    double? lng = widget.existing?.longitude;

    try {
      final geo = ServiceLocator.getIt<GeocodingService>();
      final result = await geo.geocodeAddress(rua: rua, numero: num, bairro: bairro, cidade: cidade, uf: uf);
      if (result != null) {
        lat = result.lat;
        lng = result.lng;
        if (mounted) setState(() => _geoStatus = 'Localização encontrada ✓');
      } else {
        if (mounted) setState(() => _geoStatus = 'Localização não encontrada (salvo sem coordenadas)');
      }
    } catch (_) {
      if (mounted) setState(() => _geoStatus = 'Erro ao localizar (salvo sem coordenadas)');
    }

    final repo = ServiceLocator.getIt<SalaRepository>();
    final address = StudentAddress(
      id: widget.existing?.id ?? '',
      label: _labelCtrl.text.trim(),
      logradouro: rua, numero: num, complemento: _compCtrl.text.trim(),
      bairro: bairro, cep: _cepCtrl.text.trim(), localidade: cidade, uf: uf,
      latitude: lat, longitude: lng,
      isDefault: widget.existing?.isDefault ?? false,
    );

    try {
      if (_isEdit) {
        await repo.updateAddress(userId: widget.userId, address: address);
      } else {
        await repo.addAddress(userId: widget.userId, address: address);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(_isEdit ? 'Editar Endereço' : 'Novo Endereço', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Text('Nome (rótulo)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _labelCtrl, label: 'Ex: Casa, Trabalho, República', prefixIcon: Icons.label_outline_rounded),
        const SizedBox(height: 16),
        const Text('CEP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _cepCtrl, label: '00000-000', prefixIcon: Icons.location_on_outlined, keyboardType: TextInputType.number, onChanged: _buscarCep),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rua', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 8),
            AppTextField(controller: _ruaCtrl, label: 'Rua')])),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nº', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 8),
            AppTextField(controller: _numCtrl, label: '000', keyboardType: TextInputType.number)])),
        ]),
        const SizedBox(height: 12),
        const Text('Complemento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _compCtrl, label: 'Apto, bloco... (opcional)'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bairro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 8),
            AppTextField(controller: _bairroCtrl, label: 'Bairro')])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cidade', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 8),
            AppTextField(controller: _cidadeCtrl, label: 'Cidade')])),
          const SizedBox(width: 12),
          SizedBox(width: 60, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('UF', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), const SizedBox(height: 8),
            AppTextField(controller: _ufCtrl, label: 'MG')])),
        ]),
        if (_geoStatus != null) Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(_geoStatus!, style: const TextStyle(color: AppTheme.info, fontSize: 12))),
        const SizedBox(height: 24),
        AppButton(label: _isEdit ? 'Salvar alterações' : 'Salvar', isLoading: _saving, onPressed: _save),
      ])),
    );
  }
}
