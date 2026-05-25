import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_header.dart';

class DriverDashboardTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverDashboardTab({super.key, required this.viewModel});
  @override
  State<DriverDashboardTab> createState() => _DriverDashboardTabState();
}

class _DriverDashboardTabState extends State<DriverDashboardTab> {
  // TODO: Carregar do Firestore via stream
  // Dados mockados temporariamente para UI preview
  final int _totalStudents = 0;
  final int _confirmedToday = 0;
  final int _pendingToday = 0;
  final int _releasedToday = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    if (user == null) return const SizedBox();

    // Se não tem sala, mostra tela de setup
    if (user.salaId == null) return _buildNeedsSalaView(context, user.primeiroNome);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(user.primeiroNome),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 28),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              _buildTodaySummary(),
              const SizedBox(height: 28),
              _buildRecentAlerts(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeedsSalaView(BuildContext context, String nome) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.add_home_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Olá, $nome!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text(
                'Para começar, crie uma sala e compartilhe o código com seus alunos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.grey500, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createSala),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Criar minha sala', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                    elevation: 0,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(String nome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreetingText(),
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(nome, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: AppTheme.radiusFull,
                  ),
                  child: Text(
                    _totalStudents > 0 ? '$_confirmedToday/$_totalStudents confirmados hoje' : 'Nenhum aluno cadastrado',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  String _getGreetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Alunos',
            value: '$_totalStudents',
            icon: Icons.people_rounded,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Confirmados',
            value: '$_confirmedToday',
            icon: Icons.check_circle_rounded,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Ações rápidas'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _quickAction(
              'Chamada',
              Icons.fact_check_rounded,
              AppTheme.warning,
              () => Navigator.of(context).pushNamed(AppRoutes.attendanceOverview),
            )),
            const SizedBox(width: 12),
            Expanded(child: _quickAction(
              'Faculdades',
              Icons.school_rounded,
              AppTheme.accent,
              () => Navigator.of(context).pushNamed(AppRoutes.manageFaculdades),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickAction(
              'Montar Rota',
              Icons.alt_route_rounded,
              AppTheme.success,
              () => Navigator.of(context).pushNamed(AppRoutes.routeBuilder),
            )),
            const SizedBox(width: 12),
            Expanded(child: _quickAction(
              'Iniciar Rota',
              Icons.navigation_rounded,
              AppTheme.primary,
              () => Navigator.of(context).pushNamed(AppRoutes.activeRoute),
            )),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: AppTheme.radiusLg,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: AppTheme.radiusMd),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.grey300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.today_rounded, color: AppTheme.warning, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Resumo de hoje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _summaryRow('Ida e Volta', '0', AppTheme.primary, Icons.swap_horiz_rounded),
          const SizedBox(height: 12),
          _summaryRow('Só Ida', '0', AppTheme.info, Icons.arrow_forward_rounded),
          const SizedBox(height: 12),
          _summaryRow('Só Volta', '0', AppTheme.accent, Icons.arrow_back_rounded),
          const SizedBox(height: 12),
          _summaryRow('Não vai', '0', AppTheme.error, Icons.close_rounded),
          const SizedBox(height: 12),
          _summaryRow('Pendente', '$_pendingToday', AppTheme.warning, Icons.schedule_rounded),
          const Divider(height: 28),
          _summaryRow('Liberados', '$_releasedToday', AppTheme.success, Icons.exit_to_app_rounded),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: AppTheme.radiusFull),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.notifications_active_rounded, color: AppTheme.success, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Liberações', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          // Empty state
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
            child: const Column(
              children: [
                Icon(Icons.notifications_none_rounded, color: AppTheme.grey300, size: 32),
                SizedBox(height: 8),
                Text('Nenhuma liberação ainda', style: TextStyle(color: AppTheme.grey400, fontSize: 13)),
                Text('Os alunos liberados aparecerão aqui', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
