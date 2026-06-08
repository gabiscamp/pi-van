import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/sala.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ManageSalasPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const ManageSalasPage({super.key, required this.viewModel});
  @override
  State<ManageSalasPage> createState() => _ManageSalasPageState();
}

class _ManageSalasPageState extends State<ManageSalasPage> {
  List<Sala> _salas = [];
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
      final salas = await ServiceLocator.getIt<SalaRepository>().getSalasByDriver(_userId);
      if (mounted) setState(() { _salas = salas; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _SalaSheet(viewModel: widget.viewModel),
    );
    if (result == true) {
      await widget.viewModel.reloadUser();
      _load();
    }
  }

  Future<void> _edit(Sala sala) async {
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _SalaSheet(viewModel: widget.viewModel, existing: sala),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Sala sala) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Excluir sala?'),
      content: Text('Excluir "${sala.name}"? Os alunos serão desvinculados desta sala. Esta ação não pode ser desfeita.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: AppTheme.error))),
      ],
    ));
    if (ok != true) return;

    await ServiceLocator.getIt<SalaRepository>().deleteSala(sala.id);

    // Se a sala excluída era a ativa, troca para outra (ou nenhuma).
    final user = widget.viewModel.currentUser;
    if (user != null) {
      final remaining = List<String>.from(user.salaIds)..remove(sala.id);
      final newActive = user.salaId == sala.id
          ? (remaining.isNotEmpty ? remaining.first : null)
          : user.salaId;
      final updated = user.copyWith(salaId: newActive, salaIds: remaining);
      try {
        await ServiceLocator.getIt<AuthRepository>().updateUser(updated);
      } catch (_) {}
      widget.viewModel.updateCurrentUser(updated);
    }
    _load();
  }

  Future<void> _viewStudents(Sala sala) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _SalaStudentsSheet(salaId: sala.id, salaName: sala.name),
    );
  }

  void _setActive(Sala sala) {
    widget.viewModel.selectSala(sala.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sala "${sala.name}" ativada'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeId = widget.viewModel.currentUser?.salaId;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Minhas Salas'), backgroundColor: AppTheme.white, surfaceTintColor: Colors.transparent),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _salas.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
                    child: const Icon(Icons.meeting_room_outlined, color: AppTheme.primary, size: 40)),
                  const SizedBox(height: 20),
                  const Text('Nenhuma sala', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Crie uma sala e compartilhe o código com seus alunos.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 24),
                  AppButton(label: 'Criar sala', icon: Icons.add_rounded, onPressed: _create),
                ])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  itemCount: _salas.length,
                  itemBuilder: (_, i) => _salaCard(_salas[i], _salas[i].id == activeId),
                ),
      floatingActionButton: _salas.isNotEmpty
          ? FloatingActionButton.extended(onPressed: _create, backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded), label: const Text('Nova sala'), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd))
          : null,
    );
  }

  Widget _salaCard(Sala sala, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow,
        border: isActive ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(sala.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis)),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusFull),
                  child: const Text('Ativa', style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700))),
              ],
            ]),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: sala.accessCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                );
              },
              child: Row(children: [
                const Icon(Icons.vpn_key_rounded, size: 13, color: AppTheme.grey500),
                const SizedBox(width: 4),
                Text(sala.accessCode, style: const TextStyle(color: AppTheme.grey600, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 12, color: AppTheme.grey400),
              ]),
            ),
          ])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _viewStudents(sala),
            icon: const Icon(Icons.people_outline_rounded, size: 16),
            label: const Text('Alunos'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(vertical: 10)),
          )),
          const SizedBox(width: 8),
          if (!isActive)
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _setActive(sala),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Usar'),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.success, side: BorderSide(color: AppTheme.success.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
          if (!isActive) const SizedBox(width: 8),
          IconButton(
            onPressed: () => _edit(sala),
            icon: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
              child: const Icon(Icons.edit_outlined, color: AppTheme.grey600, size: 18)),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _delete(sala),
            icon: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: AppTheme.radiusMd),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18)),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }
}

class _SalaSheet extends StatefulWidget {
  final AuthViewModel viewModel;
  final Sala? existing;
  const _SalaSheet({required this.viewModel, this.existing});
  @override
  State<_SalaSheet> createState() => _SalaSheetState();
}

class _SalaSheetState extends State<_SalaSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _createdCode;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para a sala'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ServiceLocator.getIt<SalaRepository>();
    try {
      if (_isEdit) {
        await repo.updateSala(salaId: widget.existing!.id, name: _nameCtrl.text.trim());
        if (mounted) Navigator.pop(context, true);
      } else {
        final user = widget.viewModel.currentUser!;
        final sala = await repo.createSala(name: _nameCtrl.text.trim(), driverId: user.id, driverName: user.name);
        final newSalaIds = List<String>.from(user.salaIds);
        if (!newSalaIds.contains(sala.id)) newSalaIds.add(sala.id);
        final updatedUser = user.copyWith(salaId: sala.id, salaIds: newSalaIds);
        await ServiceLocator.getIt<AuthRepository>().updateUser(updatedUser);
        widget.viewModel.updateCurrentUser(updatedUser);
        if (mounted) setState(() { _createdCode = sala.accessCode; _saving = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: _createdCode != null ? _successView() : _formView(),
    );
  }

  Widget _formView() {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Text(_isEdit ? 'Editar Sala' : 'Nova Sala', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 24),
      const Text('Nome da sala', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 8),
      AppTextField(controller: _nameCtrl, label: 'Ex: Van do Ricardo - BH', prefixIcon: Icons.meeting_room_outlined),
      const SizedBox(height: 24),
      AppButton(label: _isEdit ? 'Salvar' : 'Criar Sala', isLoading: _saving, onPressed: _save),
    ]);
  }

  Widget _successView() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 20),
      Container(width: 64, height: 64, decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 36)),
      const SizedBox(height: 16),
      const Text('Sala criada!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Compartilhe o código com seus alunos.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
      const SizedBox(height: 20),
      Container(width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(gradient: AppTheme.heroGradient, borderRadius: AppTheme.radiusXl),
        child: Column(children: [
          Text('Código de acesso', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 8),
          Text(_createdCode!, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 8)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _createdCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
              );
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppTheme.radiusFull),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.copy_rounded, color: Colors.white, size: 16), SizedBox(width: 8),
                Text('Copiar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ])),
          ),
        ])),
      const SizedBox(height: 20),
      AppButton(label: 'Concluir', onPressed: () => Navigator.pop(context, true)),
    ]);
  }
}

class _SalaStudentsSheet extends StatefulWidget {
  final String salaId;
  final String salaName;
  const _SalaStudentsSheet({required this.salaId, required this.salaName});
  @override
  State<_SalaStudentsSheet> createState() => _SalaStudentsSheetState();
}

class _SalaStudentsSheetState extends State<_SalaStudentsSheet> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ServiceLocator.getIt<SalaRepository>().getStudents(widget.salaId);
      if (mounted) setState(() { _students = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Alunos · ${widget.salaName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${_students.length} aluno(s) vinculado(s)', style: const TextStyle(color: AppTheme.grey500, fontSize: 13)),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else if (_students.isEmpty)
          Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
            child: const Center(child: Text('Nenhum aluno nesta sala ainda', style: TextStyle(color: AppTheme.grey500, fontSize: 13))))
        else
          Flexible(child: ListView.builder(
            shrinkWrap: true,
            itemCount: _students.length,
            itemBuilder: (_, i) {
              final s = _students[i];
              final name = s['name'] as String? ?? 'Aluno';
              return Container(
                margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                ]),
              );
            },
          )),
      ]),
    );
  }
}
