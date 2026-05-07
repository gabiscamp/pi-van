import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';

class HomeDriverPage extends StatelessWidget {
  const HomeDriverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Painel do Motorista',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSalaCard(),
            const SizedBox(height: 24),
            _buildFaculdadesSection(context),
            const SizedBox(height: 24),
            _buildStudentsSection(),
            const SizedBox(height: 24),
            AppButton(
              label: 'Ver chamada de hoje',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Van Manhã',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Código: VAN001',
                      style: TextStyle(color: Color(0xFFE5E7EB)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                    Icons.directions_bus, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaculdadesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Faculdades atendidas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildFaculdadeItem('Faculdade Central', Icons.school),
        const SizedBox(height: 8),
        _buildFaculdadeItem('Faculdade Norte', Icons.school),
      ],
    );
  }

  Widget _buildFaculdadeItem(String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alunos (3)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildStudentItem('Maria Souza', 'Confirmado', true),
        const SizedBox(height: 8),
        _buildStudentItem('Pedro Lima', 'Pendente', false),
        const SizedBox(height: 8),
        _buildStudentItem('Ana Dias', 'Confirmado', true),
      ],
    );
  }

  Widget _buildStudentItem(String name, String status, bool confirmed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: confirmed
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              confirmed ? Icons.check_circle : Icons.schedule,
              color: confirmed
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
