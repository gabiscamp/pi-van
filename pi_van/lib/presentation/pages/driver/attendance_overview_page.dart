import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';

class AttendanceOverviewPage extends StatefulWidget {
  const AttendanceOverviewPage({super.key});
  @override
  State<AttendanceOverviewPage> createState() => _AttendanceOverviewPageState();
}

class _AttendanceOverviewPageState extends State<AttendanceOverviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Substituir por stream do Firestore
  // salas/{salaId}/attendance/{hoje}/votes
  final List<_StudentVote> _allVotes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Chamada de Hoje'),
        backgroundColor: AppTheme.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: AppTheme.radiusXl,
            ),
            child: Column(
              children: [
                Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  '${_allVotes.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                ),
                Text('alunos no total', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBubble('Ida+Volta', _allVotes.where((v) => v.status == 'vaiEVolta').length.toString(), Colors.white),
                    _statBubble('Só Ida', _allVotes.where((v) => v.status == 'soIda').length.toString(), Colors.white),
                    _statBubble('Só Volta', _allVotes.where((v) => v.status == 'soVolta').length.toString(), Colors.white),
                    _statBubble('Não vai', _allVotes.where((v) => v.status == 'naoVai').length.toString(), Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppTheme.grey100,
              borderRadius: AppTheme.radiusMd,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.white,
                borderRadius: AppTheme.radiusMd,
                boxShadow: AppTheme.cardShadow,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.grey500,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Todos'),
                Tab(text: 'Ida'),
                Tab(text: 'Volta'),
                Tab(text: 'Liberados'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVoteList(_allVotes),
                _buildVoteList(_allVotes.where((v) => v.status == 'vaiEVolta' || v.status == 'soIda').toList()),
                _buildVoteList(_allVotes.where((v) => v.status == 'vaiEVolta' || v.status == 'soVolta').toList()),
                _buildVoteList(_allVotes.where((v) => v.liberado).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBubble(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildVoteList(List<_StudentVote> votes) {
    if (votes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.people_outline_rounded, color: AppTheme.grey300, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Nenhum registro', style: TextStyle(color: AppTheme.grey400, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Os votos dos alunos aparecerão aqui', style: TextStyle(color: AppTheme.grey400, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: votes.length,
      itemBuilder: (_, i) {
        final v = votes[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: AppTheme.radiusMd,
            boxShadow: AppTheme.cardShadow,
            border: v.liberado ? Border.all(color: AppTheme.success.withOpacity(0.3)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(v.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(v.faculdade ?? '-', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  ],
                ),
              ),
              if (v.liberado)
                StatusBadge.released()
              else
                _statusChip(v.status),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    switch (status) {
      case 'vaiEVolta':
        return const StatusBadge(label: 'Ida+Volta', color: AppTheme.primary, icon: Icons.swap_horiz_rounded);
      case 'soIda':
        return const StatusBadge(label: 'Só Ida', color: AppTheme.info, icon: Icons.arrow_forward_rounded);
      case 'soVolta':
        return const StatusBadge(label: 'Só Volta', color: AppTheme.accent, icon: Icons.arrow_back_rounded);
      case 'naoVai':
        return StatusBadge.absent();
      default:
        return StatusBadge.pending();
    }
  }
}

class _StudentVote {
  final String name;
  final String status;
  final bool liberado;
  final String? faculdade;
  _StudentVote({required this.name, required this.status, this.liberado = false, this.faculdade});
}
