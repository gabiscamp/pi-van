import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/repositories/sala_repository.dart';
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
  StreamSubscription? _studentsSub;
  StreamSubscription? _attendanceSub;

  int _totalStudents = 0;
  int _confirmedToday = 0;
  int _pendingToday = 0;
  int _releasedToday = 0;
  List<Map<String, dynamic>> _recentReleases = [];
  final Set<String> _notifiedLiberados = {};

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  @override
  void dispose() {
    _studentsSub?.cancel();
    _attendanceSub?.cancel();
    super.dispose();
  }

  void _startStreams() {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;
    final repo = ServiceLocator.getIt<SalaRepository>();

    _studentsSub = repo.studentsStream(user!.salaId!).listen((students) {
      if (mounted) setState(() => _totalStudents = students.length);
    });

    _attendanceSub = repo.attendanceStream(salaId: user.salaId!, date: _today).listen((votes) {
      if (!mounted) return;
      int confirmed = 0, pending = 0, released = 0;
      final releases = <Map<String, dynamic>>[];

      votes.forEach((userId, data) {
        final status = data['status'] as String?;
        if (status == 'vaiEVolta' || status == 'soIda' || status == 'soVolta') {
          confirmed++;
        } else if (status == null || status == 'pendente') { pending++; }
        if (data['liberado'] == true) {
          released++;
          final nome = data['userName'] as String? ?? 'Aluno';
          final fac = data['faculdadeName'] as String? ?? '';
          releases.add({'name': nome, 'time': data['liberadoAt'] ?? '', 'faculdade': fac});
          // Notificação sonora (apenas uma vez por aluno)
          if (!_notifiedLiberados.contains(userId)) {
            _notifiedLiberados.add(userId);
            NotificationService.showLiberado(userId, nome, fac);
          }
        }
      });

      setState(() {
        _confirmedToday = confirmed;
        _pendingToday = _totalStudents - votes.length + pending;
        _releasedToday = released;
        _recentReleases = releases;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    if (user == null) return const SizedBox();
    if (user.salaId == null) return _buildNeedsSalaView(context, user.primeiroNome);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildGreeting(user.primeiroNome),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: StatCard(title: 'Alunos', value: '$_totalStudents', icon: Icons.people_rounded, color: AppTheme.primary)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: 'Confirmados', value: '$_confirmedToday', icon: Icons.check_circle_rounded, color: AppTheme.success)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(title: 'Pendentes', value: '$_pendingToday', icon: Icons.schedule_rounded, color: AppTheme.warning)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(title: 'Liberados', value: '$_releasedToday', icon: Icons.exit_to_app_rounded, color: AppTheme.accent)),
            ]),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Ações rápidas'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _quickAction('Chamada', Icons.fact_check_rounded, AppTheme.warning, () => Navigator.of(context).pushNamed(AppRoutes.attendanceOverview))),
              const SizedBox(width: 12),
              Expanded(child: _quickAction('Faculdades', Icons.school_rounded, AppTheme.accent, () => Navigator.of(context).pushNamed(AppRoutes.manageFaculdades))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _quickAction('Montar Rota', Icons.alt_route_rounded, AppTheme.success, () => Navigator.of(context).pushNamed(AppRoutes.routeBuilder))),
              const SizedBox(width: 12),
              Expanded(child: _quickAction('Salas', Icons.meeting_room_rounded, AppTheme.primary, () => Navigator.of(context).pushNamed(AppRoutes.manageSalas))),
            ]),
            const SizedBox(height: 28),
            // Liberações recentes
            _buildRecentReleases(),
          ]),
        ),
      ),
    );
  }

  Widget _buildNeedsSalaView(BuildContext context, String nome) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Spacer(),
        Container(width: 80, height: 80, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.add_home_rounded, color: Colors.white, size: 40)),
        const SizedBox(height: 24),
        Text('Olá, $nome!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text('Para começar, crie uma sala e compartilhe o código com seus alunos.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 15, height: 1.5)),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createSala),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Criar minha sala', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
        )),
        const Spacer(),
      ]))),
    );
  }

  Widget _buildGreeting(String nome) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bom dia,' : (hour < 18 ? 'Boa tarde,' : 'Boa noite,');
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppTheme.heroGradient, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.elevatedShadow),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(greeting, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 4),
          Text(nome, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppTheme.radiusFull),
            child: Text(_totalStudents > 0 ? '$_confirmedToday/$_totalStudents confirmados' : 'Nenhum aluno cadastrado',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ])),
        Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 32)),
      ]),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppTheme.radiusMd), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
        Icon(Icons.chevron_right_rounded, color: AppTheme.grey300, size: 20),
      ]),
    ));
  }

  Widget _buildRecentReleases() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
      child: Column(children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
            child: const Icon(Icons.notifications_active_rounded, color: AppTheme.success, size: 18)),
          const SizedBox(width: 12),
          Text('Liberações ($_releasedToday)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 16),
        if (_recentReleases.isEmpty)
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: AppTheme.radiusMd),
            child: const Column(children: [
              Icon(Icons.notifications_none_rounded, color: AppTheme.grey300, size: 32),
              SizedBox(height: 8),
              Text('Nenhuma liberação ainda', style: TextStyle(color: AppTheme.grey400, fontSize: 13)),
            ]))
        else
          ...(_recentReleases.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: AppTheme.radiusMd),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('${r['name']} liberado', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              if ((r['faculdade'] as String).isNotEmpty)
                Text(r['faculdade'], style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
            ]),
          ))),
      ]),
    );
  }
}
