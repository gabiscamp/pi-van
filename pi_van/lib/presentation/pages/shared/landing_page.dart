import 'package:flutter/material.dart';
import '../../../core/routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

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
              _buildHeader(context),
              const SizedBox(height: 28),
              _buildHero(),
              const SizedBox(height: 24),
              _buildJoinCard(context),
              const SizedBox(height: 24),
              _buildFeatureGrid(),
              const SizedBox(height: 24),
              _buildDriverCta(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        const Text('VanGo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.grey900)),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
          child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        gradient: AppTheme.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppTheme.radiusFull,
            ),
            child: const Text(
              '🚐  Transporte escolar simplificado',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Seu transporte\nescolar em um\nsó lugar',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Chamada diária, rotas otimizadas e localização em tempo real.',
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard(BuildContext context) {
    return Container(
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
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: AppTheme.radiusMd),
                child: const Icon(Icons.vpn_key_rounded, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Entrar na sala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('Digite o código do motorista', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(controller: _codeController, label: 'Código', hintText: 'EX: ABC123'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.login, arguments: AppRoutes.joinSala);
                  },
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Como funciona', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _FeatureCard(title: 'Chamada diária', desc: 'Informe se vai ou não todo dia.', icon: Icons.how_to_vote_rounded, color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _FeatureCard(title: 'Rota otimizada', desc: 'Melhor caminho calculado.', icon: Icons.alt_route_rounded, color: AppTheme.success)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _FeatureCard(title: 'Localização', desc: 'Acompanhe a van ao vivo.', icon: Icons.location_on_rounded, color: AppTheme.warning)),
            const SizedBox(width: 12),
            Expanded(child: _FeatureCard(title: 'Notificações', desc: 'Saiba quando a van chegar.', icon: Icons.notifications_active_rounded, color: AppTheme.accent)),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('É motorista de van?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Cadastre-se e gerencie seus alunos, chamadas e rotas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
              child: const Text('Cadastrar como Motorista', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title, desc;
  final IconData icon;
  final Color color;

  const _FeatureCard({required this.title, required this.desc, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: AppTheme.radiusMd),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: AppTheme.grey500, fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}
