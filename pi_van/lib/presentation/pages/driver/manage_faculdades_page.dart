import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/faculdade.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
  void initState() {
    super.initState();
    _loadFaculdades();
  }

  Future<void> _loadFaculdades() async {
    if (_salaId.isEmpty) return;
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final facs = await repo.getFaculdades(_salaId);
      if (mounted) setState(() { _faculdades = facs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFaculdade() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFaculdadeSheet(salaId: _salaId),
    );
    if (result == true) _loadFaculdades();
  }

  Future<void> _removeFaculdade(Faculdade fac) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
        title: const Text('Remover faculdade?'),
        content: Text('Tem certeza que deseja remover "${fac.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.removeFaculdade(salaId: _salaId, faculdadeId: fac.id);
      _loadFaculdades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculdade removida'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Faculdades'),
        backgroundColor: AppTheme.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _addFaculdade,
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _faculdades.isEmpty
              ? _buildEmptyState()
              : _buildList(),
      floatingActionButton: _faculdades.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addFaculdade,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w700)),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.school_outlined, color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Nenhuma faculdade', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Adicione as faculdades que você atende para que os alunos possam escolher a deles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Adicionar faculdade', icon: Icons.add_rounded, onPressed: _addFaculdade),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _faculdades.length,
      itemBuilder: (_, index) {
        final fac = _faculdades[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.radiusLg,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fac.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (fac.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(fac.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeFaculdade(fac),
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: AppTheme.radiusMd),
                  child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddFaculdadeSheet extends StatefulWidget {
  final String salaId;
  const _AddFaculdadeSheet({required this.salaId});
  @override
  State<_AddFaculdadeSheet> createState() => _AddFaculdadeSheetState();
}

class _AddFaculdadeSheetState extends State<_AddFaculdadeSheet> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.addFaculdade(
        salaId: widget.salaId,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        // TODO: Geocodificar endereço com Nominatim para obter lat/lng reais
        lat: 0.0, lng: 0.0,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          const Text('Nova Faculdade', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          const Text('Nome', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          AppTextField(controller: _nameCtrl, label: 'Ex: PUC Minas', prefixIcon: Icons.school_outlined),
          const SizedBox(height: 16),
          const Text('Endereço', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          AppTextField(controller: _addressCtrl, label: 'Ex: Av. Dom José Gaspar, 500', prefixIcon: Icons.location_on_outlined),
          const SizedBox(height: 24),
          AppButton(label: 'Salvar', isLoading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
