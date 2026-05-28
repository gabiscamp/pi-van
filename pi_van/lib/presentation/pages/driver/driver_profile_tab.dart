import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/sala.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';

class DriverProfileTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverProfileTab({super.key, required this.viewModel});
  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  List<Sala> _salas = [];
  bool _loadingSalas = true;

  Sala? get _activeSala {
    final salaId = widget.viewModel.currentUser?.salaId;
    if (salaId == null) return null;
    try { return _salas.firstWhere((s) => s.id == salaId); } catch (_) { return _salas.isEmpty ? null : _salas.first; }
  }

  @override
  void initState() { super.initState(); _loadSalas(); }

  Future<void> _loadSalas() async {
    final user = widget.viewModel.currentUser;
    if (user == null) { setState(() => _loadingSalas = false); return; }
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final salas = await repo.getSalasByDriver(user.id);
      if (mounted) setState(() { _salas = salas; _loadingSalas = false; });
      if (salas.isNotEmpty && user.salaId == null) widget.viewModel.selectSala(salas.first.id);
    } catch (_) { if (mounted) setState(() => _loadingSalas = false); }
  }

  void _selectSala(Sala sala) {
    widget.viewModel.selectSala(sala.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sala "${sala.name}" selecionada'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    if (user == null) return const SizedBox();
    final active = _activeSala;

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
              child: const Text('🚐 Motorista', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 28),

            // Código da sala ativa
            if (active != null) ...[
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: active.accessCode));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.elevatedShadow),
                  child: Column(children: [
                    Text('Sala Ativa', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(active.name, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(active.accessCode, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 8)),
                    const SizedBox(height: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppTheme.radiusFull),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.copy_rounded, color: Colors.white, size: 16), SizedBox(width: 8),
                        Text('Copiar código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ])),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Seletor de salas (aparece só se tiver mais de uma)
            if (!_loadingSalas && _salas.length > 1) ...[
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd), child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primary, size: 20)),
                    const SizedBox(width: 12),
                    const Text('Trocar de Sala', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  ..._salas.map((sala) {
                    final isActive = sala.id == widget.viewModel.currentUser?.salaId;
                    return GestureDetector(
                      onTap: () => _selectSala(sala),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryLight : AppTheme.grey50,
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(color: isActive ? AppTheme.primary : AppTheme.grey200, width: isActive ? 2 : 1),
                        ),
                        child: Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(gradient: isActive ? AppTheme.primaryGradient : null, color: isActive ? null : AppTheme.grey200, borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Icon(Icons.meeting_room_rounded, color: isActive ? Colors.white : AppTheme.grey400, size: 18))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(sala.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isActive ? AppTheme.primary : AppTheme.grey900)),
                            Text('Código: ${sala.accessCode}', style: TextStyle(color: isActive ? AppTheme.primary.withOpacity(0.7) : AppTheme.grey500, fontSize: 12)),
                          ])),
                          if (isActive) const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                        ]),
                      ),
                    );
                  }),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // Menu
            _menuItem(Icons.location_on_outlined, 'Endereço', user.enderecoCompleto),
            const SizedBox(height: 12),
            _menuItem(Icons.school_outlined, 'Faculdades', 'Gerenciar faculdades da sala', onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageFaculdades).then((_) => _loadSalas())),
            const SizedBox(height: 12),
            _menuItem(Icons.add_home_rounded, 'Nova Sala', 'Criar outra sala', onTap: () => Navigator.of(context).pushNamed(AppRoutes.createSala).then((_) async { await widget.viewModel.reloadUser(); _loadSalas(); })),
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
            Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.grey300),
        ]),
      ),
    );
  }
}
