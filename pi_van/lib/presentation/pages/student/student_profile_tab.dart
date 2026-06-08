import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/sala.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class StudentProfileTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const StudentProfileTab({super.key, required this.viewModel});
  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  List<Sala> _salas = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadSalas(); }

  Future<void> _loadSalas() async {
    // Recarrega o usuário do Firestore para garantir salaIds atualizado
    // (evita divergência entre o estado em memória e o servidor).
    await widget.viewModel.reloadUser();
    final user = widget.viewModel.currentUser;
    if (user == null || user.salaIds.isEmpty) {
      if (mounted) setState(() { _salas = []; _loading = false; });
      return;
    }
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final salas = await repo.getSalasByIds(user.salaIds);
      if (mounted) setState(() { _salas = salas; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _leaveSala(Sala sala) async {
    final user = widget.viewModel.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Sair da sala?'),
      content: Text('Deseja sair de "${sala.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair', style: TextStyle(color: AppTheme.error))),
      ],
    ));
    if (confirm != true) return;
    try {
      final salaRepo = ServiceLocator.getIt<SalaRepository>();
      await salaRepo.leaveSala(studentId: user.id, salaId: sala.id);
      final newSalaIds = List<String>.from(user.salaIds)..remove(sala.id);
      final newSalaId = newSalaIds.isNotEmpty ? newSalaIds.first : null;
      final authRepo = ServiceLocator.getIt<AuthRepository>();
      final updatedUser = user.copyWith(salaId: newSalaId, salaIds: newSalaIds);
      await authRepo.updateUser(updatedUser);
      widget.viewModel.updateCurrentUser(updatedUser);
      await _loadSalas();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saiu de "${sala.name}"'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 80, height: 80, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)),
              child: Center(child: Text(user.primeiroNome[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)))),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(user.email, style: const TextStyle(color: AppTheme.grey500, fontSize: 14)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusFull),
              child: const Text('🎓 Estudante', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 28),

            // Minhas salas
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd), child: const Icon(Icons.meeting_room_rounded, color: AppTheme.primary, size: 20)),
                    const SizedBox(width: 12),
                    const Text('Minhas Salas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.joinSala).then((_) => _loadSalas()),
                    icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Entrar'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  ),
                ]),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_salas.isEmpty)
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
                    child: const Center(child: Text('Você não está em nenhuma sala', style: TextStyle(color: AppTheme.grey500, fontSize: 13))))
                else
                  ..._salas.map((sala) {
                    final isActive = sala.id == user.salaId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: isActive ? AppTheme.primaryLight : AppTheme.grey50, borderRadius: AppTheme.radiusMd,
                        border: Border.all(color: isActive ? AppTheme.primary : AppTheme.grey200, width: isActive ? 2 : 1)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(width: 36, height: 36, decoration: BoxDecoration(gradient: isActive ? AppTheme.primaryGradient : null, color: isActive ? null : AppTheme.grey200, borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Icon(Icons.school_rounded, color: isActive ? Colors.white : AppTheme.grey400, size: 18))),
                        title: Text(sala.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isActive ? AppTheme.primary : AppTheme.grey900)),
                        subtitle: Text(isActive ? 'Sala ativa' : 'Toque em "Usar" para ativar', style: TextStyle(color: isActive ? AppTheme.primary.withValues(alpha: 0.7) : AppTheme.grey500, fontSize: 11)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (!isActive) GestureDetector(
                            onTap: () { widget.viewModel.selectSala(sala.id); setState(() {}); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sala ativada!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); },
                            child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: AppTheme.radiusFull), child: const Text('Usar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                          ),
                          if (isActive) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          GestureDetector(onTap: () => _leaveSala(sala), child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppTheme.errorLight, borderRadius: AppTheme.radiusMd), child: const Icon(Icons.exit_to_app_rounded, color: AppTheme.error, size: 16))),
                        ]),
                      ),
                    );
                  }),
              ]),
            ),
            const SizedBox(height: 16),
            _menuItem(Icons.location_on_outlined, 'Meus Endereços', 'Casa, trabalho, república...', onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageAddresses)),
            const SizedBox(height: 12),
            _menuItem(Icons.school_outlined, 'Faculdade', user.faculdadeName ?? 'Não definida'),
            const SizedBox(height: 32),

            SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
              onPressed: () async { await widget.viewModel.logout(); if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.landing, (r) => false); },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
              label: const Text('Sair da conta', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorLight), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd), child: Icon(icon, color: AppTheme.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.grey300),
        ]),
      ),
    );
  }
}
