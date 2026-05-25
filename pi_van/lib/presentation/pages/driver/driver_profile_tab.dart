import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';

class DriverProfileTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverProfileTab({super.key, required this.viewModel});
  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  String? _salaCode;
  String? _salaName;

  @override
  void initState() {
    super.initState();
    _loadSalaInfo();
  }

  Future<void> _loadSalaInfo() async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;
    try {
      final salaRepo = ServiceLocator.getIt<SalaRepository>();
      final sala = await salaRepo.getSalaById(user!.salaId!);
      if (sala != null && mounted) {
        setState(() {
          _salaCode = sala.accessCode;
          _salaName = sala.name;
        });
      }
    } catch (_) {}
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Avatar
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: Center(child: Text(user.primeiroNome[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(user.email, style: const TextStyle(color: AppTheme.grey500, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusFull),
                child: const Text('🚐 Motorista', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 28),

              // Código da sala
              if (_salaCode != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.radiusXl,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    children: [
                      Text('Código da Sala', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(_salaCode!, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 6)),
                      if (_salaName != null) ...[
                        const SizedBox(height: 4),
                        Text(_salaName!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                      ],
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _salaCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: AppTheme.radiusFull),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Copiar código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Menu items
              _menuItem(Icons.location_on_outlined, 'Endereço', user.enderecoCompleto),
              const SizedBox(height: 12),
              _menuItem(Icons.school_outlined, 'Faculdades', 'Gerenciar faculdades', onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageFaculdades)),
              const SizedBox(height: 12),
              _menuItem(Icons.meeting_room_outlined, 'Sala', _salaName ?? 'Sem sala'),
              const SizedBox(height: 32),

              // Logout
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.viewModel.logout();
                    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.landing, (r) => false);
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  label: const Text('Sair da conta', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorLight), shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd)),
                ),
              ),
            ],
          ),
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
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.grey300),
          ],
        ),
      ),
    );
  }
}
