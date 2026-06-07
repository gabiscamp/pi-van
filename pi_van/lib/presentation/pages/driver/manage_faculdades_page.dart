import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../domain/entities/faculdade.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../../core/via_cep_service.dart';

class ManageFaculdadesPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const ManageFaculdadesPage({super.key, required this.viewModel});
  @override
  State<ManageFaculdadesPage> createState() => _ManageFaculdadesPageState();
}

class _ManageFaculdadesPageState extends State<ManageFaculdadesPage> {
  List<Faculdade> _faculdades = [];
  bool _loading = true;
  String get _salaId => widget.viewModel.currentUser?.salaId ?? '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (_salaId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final facs = await ServiceLocator.getIt<SalaRepository>().getFaculdades(_salaId);
      if (mounted) setState(() { _faculdades = facs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_salaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie uma sala antes de adicionar faculdades.'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddFacSheet(salaId: _salaId));
    if (result == true) _load();
  }

  Future<void> _edit(Faculdade fac) async {
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _AddFacSheet(salaId: _salaId, existing: fac));
    if (result == true) _load();
  }

  Future<void> _remove(Faculdade fac) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Remover?'), content: Text('Remover "${fac.name}"?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover', style: TextStyle(color: AppTheme.error)))],
    ));
    if (ok != true) return;
    await ServiceLocator.getIt<SalaRepository>().removeFaculdade(salaId: _salaId, faculdadeId: fac.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Faculdades'), backgroundColor: AppTheme.white, surfaceTintColor: Colors.transparent),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _faculdades.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.school_outlined, color: AppTheme.primary, size: 40)),
            const SizedBox(height: 20), const Text('Nenhuma faculdade', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 24), AppButton(label: 'Adicionar faculdade', icon: Icons.add_rounded, onPressed: _add),
          ])))
        : ListView.builder(padding: const EdgeInsets.fromLTRB(20, 16, 20, 80), itemCount: _faculdades.length, itemBuilder: (_, i) {
            final f = _faculdades[i];
            return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  if (f.address.isNotEmpty) Text(f.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (f.latitude != 0) Text('📍 ${f.latitude.toStringAsFixed(4)}, ${f.longitude.toStringAsFixed(4)}', style: const TextStyle(color: AppTheme.success, fontSize: 11)),
                ])),
                IconButton(onPressed: () => _edit(f), icon: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusMd),
                  child: const Icon(Icons.edit_outlined, color: AppTheme.info, size: 18))),
                IconButton(onPressed: () => _remove(f), icon: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: AppTheme.radiusMd),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18))),
              ]));
          }),
      floatingActionButton: _faculdades.isNotEmpty ? FloatingActionButton.extended(onPressed: _add, backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white, icon: const Icon(Icons.add_rounded), label: const Text('Adicionar'),
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)) : null,
    );
  }
}

class _AddFacSheet extends StatefulWidget {
  final String salaId;
  final Faculdade? existing;
  const _AddFacSheet({required this.salaId, this.existing});
  @override
  State<_AddFacSheet> createState() => _AddFacSheetState();
}

class _AddFacSheetState extends State<_AddFacSheet> {
  final _nameCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  bool _saving = false;
  String? _geoStatus;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      // Mostra o endereço atual; a geocodificação será refeita ao salvar
      // apenas se o motorista editar os campos estruturados.
      _ruaCtrl.text = e.address;
    }
  }

  @override
  void dispose() { for (var c in [_nameCtrl, _cepCtrl, _ruaCtrl, _numCtrl, _bairroCtrl, _cidadeCtrl, _ufCtrl]) {
    c.dispose();
  } super.dispose(); }

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
    if (_nameCtrl.text.trim().isEmpty) return;
    if (widget.salaId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: sala não identificada. Volte e tente novamente.'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() { _saving = true; _geoStatus = 'Geocodificando endereço...'; });

    // Geocodificar
    double lat = 0, lng = 0;
    final rua = _ruaCtrl.text.trim();
    final num = _numCtrl.text.trim();
    final bairro = _bairroCtrl.text.trim();
    final cidade = _cidadeCtrl.text.trim();
    final uf = _ufCtrl.text.trim();
    final addressParts = [if (rua.isNotEmpty) rua, if (num.isNotEmpty) num, if (bairro.isNotEmpty) bairro, if (cidade.isNotEmpty) cidade, if (uf.isNotEmpty) uf];
    final address = addressParts.join(', ');
    final editing = widget.existing != null;
    // Ao editar, parte das coordenadas já existentes; só re-geocodifica se o
    // motorista preencheu campos estruturados de endereço.
    if (editing) {
      lat = widget.existing!.latitude;
      lng = widget.existing!.longitude;
    }
    final shouldGeocode = !editing || cidade.isNotEmpty || bairro.isNotEmpty;
    if (shouldGeocode) {
      try {
        final geo = ServiceLocator.getIt<GeocodingService>();
        final query = address.isNotEmpty ? address : _nameCtrl.text.trim();
        final result = await geo.geocode(query);
        if (result != null) {
          lat = result.lat;
          lng = result.lng;
          if (mounted) setState(() => _geoStatus = 'Localização encontrada ✓');
        } else {
          if (mounted) setState(() => _geoStatus = 'Localização não encontrada (endereço salvo sem coordenadas)');
        }
      } catch (_) {
        if (mounted) setState(() => _geoStatus = 'Erro ao geocodificar (endereço salvo sem coordenadas)');
      }
    }

    final displayAddress = address.isNotEmpty
        ? address
        : (editing ? widget.existing!.address : _nameCtrl.text.trim());
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      if (editing) {
        await repo.updateFaculdade(
          salaId: widget.salaId, faculdadeId: widget.existing!.id,
          name: _nameCtrl.text.trim(), address: displayAddress, lat: lat, lng: lng);
      } else {
        await repo.addFaculdade(
          salaId: widget.salaId, name: _nameCtrl.text.trim(), address: displayAddress, lat: lat, lng: lng);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar faculdade: ${e.toString()}'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
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
        Text(widget.existing == null ? 'Nova Faculdade' : 'Editar Faculdade', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Text('Nome', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _nameCtrl, label: 'Ex: PUC Minas', prefixIcon: Icons.school_outlined),
        const SizedBox(height: 16),
        const Text('CEP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _cepCtrl, label: '00000-000', prefixIcon: Icons.location_on_outlined,
          keyboardType: TextInputType.number, onChanged: _buscarCep),
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
        AppButton(label: 'Salvar', isLoading: _saving, onPressed: _save),
      ])),
    );
  }
}
