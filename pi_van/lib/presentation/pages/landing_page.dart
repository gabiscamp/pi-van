import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _codeController = TextEditingController();

  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _bg = Color(0xFFF4F7FB);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildHero(),
              const SizedBox(height: 24),
              _buildJoinCard(context),
              const SizedBox(height: 24),
              _buildFeatureGrid(),
              const SizedBox(height: 24),
              _buildDriverCta(context),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'VanGo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.login);
          },
          child: const Text('Entrar'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRoutes.register);
          },
          child: const Text('Sou Motorista'),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F0FF), Color(0xFFF4F7FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Chip(
            label: Text('Transporte escolar simplificado'),
            backgroundColor: Color(0xFFDCE7FF),
            labelStyle: TextStyle(color: Color(0xFF1D4ED8)),
          ),
          SizedBox(height: 12),
          Text(
            'Seu transporte escolar em um so lugar',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Conecte motoristas e alunos de forma simples. Chamada diaria, '
            'rotas otimizadas e gestao completa.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrar na sala do motorista',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Digite o codigo fornecido pelo seu motorista',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _codeController,
                  label: 'Codigo da sala',
                  hintText: 'EX: VAN001',
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.login,
                      arguments: AppRoutes.joinSala,
                    );
                  },
                  child: const Text('Entrar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Codigo de teste: VAN001',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const [
        _FeatureCard(
          title: 'Chamada diaria',
          description: 'Alunos informam se vao ou nao, ida, volta ou ambos.',
          icon: Icons.check_circle_outline,
        ),
        _FeatureCard(
          title: 'Rota otimizada',
          description: 'Calculo automatico da melhor rota com base na chamada.',
          icon: Icons.alt_route,
        ),
        _FeatureCard(
          title: 'Organizacao por periodo',
          description: 'Separe alunos por manha, tarde e noite.',
          icon: Icons.schedule,
        ),
        _FeatureCard(
          title: 'Sala exclusiva',
          description: 'Cada motorista tem sua sala com codigo unico.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  Widget _buildDriverCta(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'E motorista de van escolar?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cadastre-se e comece a gerenciar seus alunos, '
            'chamadas e rotas hoje mesmo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFE5E7EB)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 240,
            child: AppButton(
              label: 'Cadastrar como Motorista',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.register);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _LandingPageState._primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
