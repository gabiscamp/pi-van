import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/sala_repository.dart';

class DriverStudentsTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const DriverStudentsTab({super.key, required this.viewModel});
  @override
  State<DriverStudentsTab> createState() => _DriverStudentsTabState();
}

class _DriverStudentsTabState extends State<DriverStudentsTab> {
  String _filter = 'todos';
  StreamSubscription? _studentsSub;
  StreamSubscription? _attendanceSub;
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic> _votes = {};

  String get _salaId => widget.viewModel.currentUser?.salaId ?? '';
  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    if (_salaId.isNotEmpty) _startStreams();
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _attendanceSub?.cancel();
    super.dispose();
  }

  void _startStreams() {
    final repo = ServiceLocator.getIt<SalaRepository>();
    _studentsSub = repo.studentsStream(_salaId).listen((students) {
      if (mounted) setState(() => _students = students);
    });
    _attendanceSub = repo.attendanceStream(salaId: _salaId, date: _today).listen((votes) {
      if (mounted) setState(() => _votes = votes);
    });
  }

  List<Map<String, dynamic>> get _filtered {
    return _students.where((s) {
      final id = s['userId'] as String? ?? '';
      final vote = _votes[id] as Map<String, dynamic>?;
      final status = vote?['status'] as String?;
      final liberado = vote?['liberado'] == true;
      switch (_filter) {
        case 'confirmados': return status == 'vaiEVolta' || status == 'soIda' || status == 'soVolta';
        case 'pendentes': return status == null || status == 'pendente';
        case 'liberados': return liberado;
        case 'naoVai': return status == 'naoVai';
        default: return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), color: AppTheme.background,
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: AppTheme.radiusMd),
              child: const Icon(Icons.people_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Meus Alunos', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              Text('${_students.length} alunos na sala', style: const TextStyle(color: AppTheme.grey500, fontSize: 13)),
            ])),
          ]),
        ),
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: ['todos', 'confirmados', 'pendentes', 'liberados', 'naoVai'].map((key) {
              final labels = {'todos': 'Todos', 'confirmados': 'Confirmados', 'pendentes': 'Pendentes', 'liberados': 'Liberados', 'naoVai': 'Não vai'};
              final selected = _filter == key;
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () => setState(() => _filter = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.white,
                    borderRadius: AppTheme.radiusFull,
                    border: Border.all(color: selected ? AppTheme.primary : AppTheme.grey200),
                  ),
                  child: Text(labels[key]!, style: TextStyle(color: selected ? Colors.white : AppTheme.grey600, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ));
            }).toList()),
          ),
        ),
        // List
        Expanded(child: filtered.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.people_outline_rounded, color: AppTheme.primary, size: 40)),
              const SizedBox(height: 20),
              const Text('Nenhum aluno', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Compartilhe o código da sala.', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final s = filtered[i];
                final id = s['userId'] as String? ?? '';
                final name = s['name'] as String? ?? 'Aluno';
                final vote = _votes[id] as Map<String, dynamic>?;
                final status = vote?['status'] as String?;
                final liberado = vote?['liberado'] == true;
                final faculdade = vote?['faculdadeName'] as String?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow,
                    border: liberado ? Border.all(color: AppTheme.success.withValues(alpha: 0.3)) : null,
                  ),
                  child: Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(gradient: liberado ? AppTheme.successGradient : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(faculdade ?? 'Sem faculdade', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                    ])),
                    if (liberado) StatusBadge.released()
                    else if (status == 'vaiEVolta' || status == 'soIda' || status == 'soVolta') StatusBadge.confirmed()
                    else if (status == 'naoVai') StatusBadge.absent()
                    else StatusBadge.pending(),
                  ]),
                );
              },
            ),
        ),
      ])),
    );
  }
}
