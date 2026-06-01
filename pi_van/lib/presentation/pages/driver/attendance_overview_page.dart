import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/routing/app_router.dart';
import '../../../domain/repositories/sala_repository.dart';

class AttendanceOverviewPage extends StatefulWidget {
  const AttendanceOverviewPage({super.key});
  @override
  State<AttendanceOverviewPage> createState() => _AttendanceOverviewPageState();
}

class _AttendanceOverviewPageState extends State<AttendanceOverviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription? _sub;
  Map<String, dynamic> _votes = {};

  String get _salaId => AppRouter.authViewModel.currentUser?.salaId ?? '';
  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    if (_salaId.isNotEmpty) {
      final repo = ServiceLocator.getIt<SalaRepository>();
      _sub = repo.attendanceStream(salaId: _salaId, date: _today).listen((v) {
        if (mounted) setState(() => _votes = v);
      });
    }
  }

  @override
  void dispose() { _tabController.dispose(); _sub?.cancel(); super.dispose(); }

  List<MapEntry<String, dynamic>> _filterVotes(String filter) {
    return _votes.entries.where((e) {
      final d = e.value as Map<String, dynamic>;
      final s = d['status'] as String?;
      final lib = d['liberado'] == true;
      switch (filter) {
        case 'ida': return s == 'vaiEVolta' || s == 'soIda';
        case 'volta': return s == 'vaiEVolta' || s == 'soVolta';
        case 'liberados': return lib;
        default: return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Chamada de Hoje'), backgroundColor: AppTheme.white, surfaceTintColor: Colors.transparent),
      body: Column(children: [
        Container(
          width: double.infinity, margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: AppTheme.heroGradient, borderRadius: AppTheme.radiusXl),
          child: Column(children: [
            Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
            const SizedBox(height: 8),
            Text('${_votes.length}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
            Text('votos registrados', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: AppTheme.grey100, borderRadius: AppTheme.radiusMd),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
            indicatorSize: TabBarIndicatorSize.tab, labelColor: AppTheme.primary, unselectedLabelColor: AppTheme.grey500,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'Todos'), Tab(text: 'Ida'), Tab(text: 'Volta'), Tab(text: 'Liberados')],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: TabBarView(controller: _tabController, children: [
          _buildList(_filterVotes('todos')),
          _buildList(_filterVotes('ida')),
          _buildList(_filterVotes('volta')),
          _buildList(_filterVotes('liberados')),
        ])),
      ]),
    );
  }

  Widget _buildList(List<MapEntry<String, dynamic>> votes) {
    if (votes.isEmpty) return const Center(child: Text('Nenhum registro', style: TextStyle(color: AppTheme.grey400)));
    return ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: votes.length,
      itemBuilder: (_, i) {
        final d = votes[i].value as Map<String, dynamic>;
        final name = d['userName'] as String? ?? 'Aluno';
        final status = d['status'] as String? ?? 'pendente';
        final liberado = d['liberado'] == true;
        final fac = d['faculdadeName'] as String?;
        final boarding = (d['boarding'] as Map?)?.cast<String, dynamic>();
        final dropoff = (d['dropoff'] as Map?)?.cast<String, dynamic>();
        final showAddresses = status == 'vaiEVolta' || status == 'soIda' || status == 'soVolta';
        return Container(
          margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow,
            border: liberado ? Border.all(color: AppTheme.success.withValues(alpha: 0.3)) : null),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(fac ?? '-', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
              ])),
              if (liberado) StatusBadge.released()
              else StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
            ]),
            if (showAddresses && (boarding != null || dropoff != null)) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.grey100),
              const SizedBox(height: 10),
              if (boarding != null) _addrLine(Icons.trip_origin_rounded, AppTheme.primary, 'Embarque', boarding),
              if (boarding != null && dropoff != null) const SizedBox(height: 6),
              if (dropoff != null) _addrLine(Icons.flag_rounded, AppTheme.accent, 'Desembarque', dropoff),
            ],
          ]),
        );
      },
    );
  }

  Widget _addrLine(IconData icon, Color color, String label, Map<String, dynamic> addr) {
    final aLabel = addr['label'] as String? ?? '';
    final short = addr['shortAddress'] as String? ?? '';
    final text = [if (aLabel.isNotEmpty) aLabel, if (short.isNotEmpty) short].join(' · ');
    return Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 8),
      Text('$label:', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(width: 6),
      Expanded(child: Text(text.isEmpty ? '—' : text, style: const TextStyle(color: AppTheme.grey600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  String _statusLabel(String s) {
    switch (s) { case 'vaiEVolta': return 'Ida+Volta'; case 'soIda': return 'Só Ida'; case 'soVolta': return 'Só Volta'; case 'naoVai': return 'Não vai'; default: return 'Pendente'; }
  }
  Color _statusColor(String s) {
    switch (s) { case 'vaiEVolta': return AppTheme.primary; case 'soIda': return AppTheme.info; case 'soVolta': return AppTheme.accent; case 'naoVai': return AppTheme.error; default: return AppTheme.warning; }
  }
}
