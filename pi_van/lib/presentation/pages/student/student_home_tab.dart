import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/enums/attendance_status.dart';
import '../../../domain/repositories/sala_repository.dart';

class StudentHomeTab extends StatefulWidget {
  final AuthViewModel viewModel;
  const StudentHomeTab({super.key, required this.viewModel});
  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  AttendanceStatus? _selectedStatus;
  bool _liberado = false;
  bool _saving = false;
  StreamSubscription? _attendanceSub;

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _listenAttendance();
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    super.dispose();
  }

  void _listenAttendance() {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    final repo = ServiceLocator.getIt<SalaRepository>();
    _attendanceSub = repo.attendanceStream(salaId: user!.salaId!, date: _today).listen((votes) {
      if (!mounted) return;
      final myVote = votes[user.id];
      if (myVote != null) {
        setState(() {
          final status = myVote['status'] as String?;
          if (status != null) {
            _selectedStatus = AttendanceStatus.values.firstWhere(
              (e) => e.name == status, orElse: () => AttendanceStatus.pendente,
            );
          }
          _liberado = myVote['liberado'] == true;
        });
      }
    });
  }

  Future<void> _saveVote(AttendanceStatus status) async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    // Se já votou, pergunta se quer mudar
    if (_selectedStatus != null && _selectedStatus != AttendanceStatus.pendente) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
          title: const Text('Alterar chamada?'),
          content: const Text('Você já marcou sua chamada hoje. Tem certeza que deseja alterar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _saving = true);
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.saveVote(
        salaId: user!.salaId!, date: _today, userId: user.id,
        data: {
          'status': status.name,
          'userName': user.name,
          'faculdadeId': user.faculdadeId,
          'faculdadeName': user.faculdadeName,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      setState(() => _selectedStatus = status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chamada salva: ${status.label}'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar chamada'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markLiberado() async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    setState(() => _saving = true);
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      await repo.saveVote(
        salaId: user!.salaId!, date: _today, userId: user.id,
        data: {
          'liberado': true,
          'liberadoAt': DateTime.now().toIso8601String(),
          'userName': user.name,
          'faculdadeId': user.faculdadeId,
          'faculdadeName': user.faculdadeName,
        },
      );
      setState(() => _liberado = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Motorista notificado! Você foi marcado como liberado.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao marcar liberação'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.currentUser;
    if (user == null) return const SizedBox();
    if (user.salaId == null) return _buildNeedsSalaView(context, user.primeiroNome);
    final multiSalas = (user.salaIds.length) > 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (multiSalas) _buildSalaSelector(user.salaIds, user.salaId!),
              if (multiSalas) const SizedBox(height: 12),
              _buildWelcomeHeader(user.primeiroNome),
              const SizedBox(height: 24),
              _buildInfoCards(user),
              const SizedBox(height: 24),
              _buildAttendanceSection(),
              const SizedBox(height: 24),
              _buildLiberadoSection(),
              if (_selectedStatus != null) ...[
                const SizedBox(height: 24),
                _buildCurrentStatus(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalaSelector(List<String> salaIds, String activeSalaId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, boxShadow: AppTheme.cardShadow),
      child: Row(
        children: salaIds.asMap().entries.map((e) {
          final id = e.value;
          final i = e.key;
          final isActive = id == activeSalaId;
          return Expanded(child: GestureDetector(
            onTap: () { if (!isActive) { widget.viewModel.selectSala(id); _attendanceSub?.cancel(); _listenAttendance(); } },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < salaIds.length - 1 ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: isActive ? AppTheme.primary : Colors.transparent, borderRadius: AppTheme.radiusMd),
              child: Center(child: Text('Sala ${i + 1}', style: TextStyle(color: isActive ? Colors.white : AppTheme.grey500, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
          ));
        }).toList(),
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
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Olá, $nome!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Text('Para começar, entre na sala do seu motorista usando o código.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey500, fontSize: 15, height: 1.5)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.joinSala),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Entrar na sala', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String nome) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppTheme.heroGradient, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.elevatedShadow),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Olá, $nome!', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_selectedStatus != null ? 'Chamada: ${_selectedStatus!.label}${_liberado ? ' • Liberado' : ''}' : 'Marque sua chamada de hoje',
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        ])),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
        ),
      ]),
    );
  }

  Widget _buildInfoCards(dynamic user) {
    return Row(children: [
      Expanded(child: _miniCard(Icons.meeting_room_rounded, 'Sala', 'Conectado', AppTheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: _miniCard(Icons.school_rounded, 'Faculdade', user.faculdadeName ?? 'Não definida', AppTheme.accent)),
    ]);
  }

  Widget _miniCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: AppTheme.radiusMd), child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: AppTheme.grey500, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: AppTheme.radiusMd), child: const Icon(Icons.how_to_vote_rounded, color: AppTheme.warning, size: 18)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chamada de hoje', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Selecione uma opção', style: TextStyle(color: AppTheme.grey500, fontSize: 12)),
          ]),
          if (_saving) ...[const Spacer(), const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))],
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _voteOption('Ida e Volta', Icons.swap_horiz_rounded, AppTheme.primary, AttendanceStatus.vaiEVolta)),
          const SizedBox(width: 10),
          Expanded(child: _voteOption('Só Ida', Icons.arrow_forward_rounded, AppTheme.info, AttendanceStatus.soIda)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _voteOption('Só Volta', Icons.arrow_back_rounded, AppTheme.accent, AttendanceStatus.soVolta)),
          const SizedBox(width: 10),
          Expanded(child: _voteOption('Não vou', Icons.close_rounded, AppTheme.error, AttendanceStatus.naoVai)),
        ]),
      ]),
    );
  }

  Widget _voteOption(String label, IconData icon, Color color, AttendanceStatus status) {
    final selected = _selectedStatus == status;
    return GestureDetector(
      onTap: _saving ? null : () => _saveVote(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppTheme.grey50,
          border: Border.all(color: selected ? color : AppTheme.grey200, width: selected ? 2 : 1),
          borderRadius: AppTheme.radiusMd,
        ),
        child: Column(children: [
          Icon(icon, color: selected ? color : AppTheme.grey400, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: selected ? color : AppTheme.grey600, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildLiberadoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _liberado ? AppTheme.successLight : AppTheme.white,
        borderRadius: AppTheme.radiusXl, boxShadow: AppTheme.cardShadow,
        border: _liberado ? Border.all(color: AppTheme.success, width: 2) : null,
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _liberado ? AppTheme.success.withOpacity(0.2) : AppTheme.grey100, borderRadius: AppTheme.radiusMd),
            child: Icon(_liberado ? Icons.check_circle_rounded : Icons.exit_to_app_rounded, color: _liberado ? AppTheme.success : AppTheme.grey400, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_liberado ? 'Você foi liberado!' : 'Fui liberado da faculdade',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _liberado ? AppTheme.success : AppTheme.grey900)),
            Text(_liberado ? 'O motorista foi notificado' : 'Toque quando sair da faculdade',
              style: TextStyle(color: _liberado ? AppTheme.success.withOpacity(0.8) : AppTheme.grey500, fontSize: 12)),
          ])),
        ]),
        if (!_liberado) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _markLiberado,
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Estou liberado', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.infoLight, borderRadius: AppTheme.radiusLg),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Chamada: ${_selectedStatus!.label}${_liberado ? ' • Liberado' : ''}',
          style: const TextStyle(color: AppTheme.info, fontWeight: FontWeight.w600, fontSize: 13))),
      ]),
    );
  }
}
