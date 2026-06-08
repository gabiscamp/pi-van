import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  final AuthViewModel viewModel;
  const ProfilePage({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: AppTheme.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar e nome
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: AppTheme.radiusXl,
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        user.primeiroNome.isNotEmpty ? user.primeiroNome[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppTheme.radiusFull),
                    child: Text(
                      user.role.name == 'motorista' ? '🚐 Motorista' : '🎓 Estudante',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info cards
            _infoTile(Icons.location_on_outlined, 'Endereço', user.enderecoCompleto),
            const SizedBox(height: 12),
            if (user.salaId != null)
              _infoTile(Icons.meeting_room_outlined, 'Sala', 'ID: ${user.salaId}'),
            if (user.faculdadeName != null) ...[
              const SizedBox(height: 12),
              _infoTile(Icons.school_outlined, 'Faculdade', user.faculdadeName!),
            ],
            const SizedBox(height: 32),
            // Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await viewModel.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.landing, (r) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                label: const Text('Sair da conta', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorLight),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          )),
        ],
      ),
    );
  }
}
