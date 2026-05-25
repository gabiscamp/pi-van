import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../theme/app_theme.dart';

class StudentProfileTab extends StatelessWidget {
  final AuthViewModel viewModel;
  const StudentProfileTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
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
                child: const Text('🎓 Estudante', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 32),
              // Menu items
              _menuItem(Icons.location_on_outlined, 'Meu Endereço', user.enderecoCompleto, () {}),
              const SizedBox(height: 12),
              _menuItem(Icons.school_outlined, 'Faculdade', user.faculdadeName ?? 'Não definida', () {}),
              const SizedBox(height: 12),
              _menuItem(Icons.meeting_room_outlined, 'Sala', user.salaId ?? 'Sem sala', () {}),
              const SizedBox(height: 32),
              // Logout
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await viewModel.logout();
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

  Widget _menuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
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
            const Icon(Icons.chevron_right_rounded, color: AppTheme.grey300),
          ],
        ),
      ),
    );
  }
}
