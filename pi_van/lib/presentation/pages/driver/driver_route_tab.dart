import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../domain/enums/route_type.dart';
import '../../theme/app_theme.dart';

class DriverRouteTab extends StatelessWidget {
  final AuthViewModel viewModel;
  const DriverRouteTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildRouteCards(context),
              const SizedBox(height: 24),
              _buildRouteHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rotas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              Text('Gerencie suas rotas de hoje', style: TextStyle(color: AppTheme.grey500, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCards(BuildContext context) {
    return Column(
      children: [
        _routeCard(
          context,
          title: 'Rota de Ida',
          subtitle: 'Buscar alunos em casa → Faculdades',
          icon: Icons.arrow_forward_rounded,
          color: AppTheme.primary,
          gradient: AppTheme.primaryGradient,
          onBuild: () => Navigator.of(context).pushNamed(AppRoutes.routeBuilder, arguments: RouteType.ida),
        ),
        const SizedBox(height: 16),
        _routeCard(
          context,
          title: 'Rota de Volta',
          subtitle: 'Faculdades → Deixar alunos em casa',
          icon: Icons.arrow_back_rounded,
          color: AppTheme.accent,
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)]),
          onBuild: () => Navigator.of(context).pushNamed(AppRoutes.routeBuilder, arguments: RouteType.volta),
        ),
      ],
    );
  }

  Widget _routeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required VoidCallback onBuild,
  }) {
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
                width: 48, height: 48,
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Status info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.grey400, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Monte a rota primeiro para otimizar o percurso',
                    style: TextStyle(color: AppTheme.grey500, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onBuild,
              icon: const Icon(Icons.alt_route_rounded, size: 18),
              label: const Text('Montar e iniciar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHistory() {
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
                decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.history_rounded, color: AppTheme.grey500, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Histórico de rotas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.route_outlined, color: AppTheme.grey300, size: 32),
                  SizedBox(height: 8),
                  Text('Nenhuma rota realizada', style: TextStyle(color: AppTheme.grey400, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
