import 'dart:async';
import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/enums/attendance_status.dart';
import '../../../domain/entities/attendance.dart';
import '../../../domain/entities/student_address.dart';
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

  AddressRef? _boarding;
  AddressRef? _dropoff;

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _listenAttendance();
    _syncFaculdadeToSala();
  }

  /// Garante que a faculdade do aluno esteja gravada no documento dele dentro
  /// da sala, para o motorista enxergá-la mesmo sem chamada confirmada.
  /// Repara silenciosamente alunos que entraram antes desse recurso existir.
  void _syncFaculdadeToSala() {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null || user?.faculdadeId == null) return;
    ServiceLocator.getIt<SalaRepository>().setStudentFaculdade(
      salaId: user!.salaId!,
      studentId: user.id,
      faculdadeId: user.faculdadeId,
      faculdadeName: user.faculdadeName,
    ).catchError((_) {});
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
          _boarding = AddressRef.fromMap((myVote['boarding'] as Map?)?.cast<String, dynamic>());
          _dropoff = AddressRef.fromMap((myVote['dropoff'] as Map?)?.cast<String, dynamic>());
        });
      }
    });
  }

  /// Inicia o fluxo da chamada: confirma alteração se já votou e,
  /// para status com trajeto, coleta os endereços de embarque/desembarque.
  Future<void> _startVote(AttendanceStatus status) async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    // Confirmação ao alterar voto existente.
    if (_selectedStatus != null && _selectedStatus != AttendanceStatus.pendente && _selectedStatus != status) {
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

    // "Não vou" não precisa de endereço.
    if (status == AttendanceStatus.naoVai) {
      await _saveVote(status, boarding: null, dropoff: null);
      return;
    }

    // Coleta de endereços conforme o trajeto.
    final needBoarding = status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soIda;
    final needDropoff = status == AttendanceStatus.vaiEVolta || status == AttendanceStatus.soVolta;

    final addresses = await ServiceLocator.getIt<SalaRepository>().getAddresses(user!.id);
    if (!mounted) return;

    if (addresses.isEmpty) {
      final go = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
        title: const Text('Cadastre um endereço'),
        content: const Text('Você precisa cadastrar pelo menos um endereço (casa, trabalho, república...) antes de marcar a chamada com trajeto.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Agora não')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Cadastrar')),
        ],
      ));
      if (go == true && mounted) {
        Navigator.of(context).pushNamed(AppRoutes.manageAddresses);
      }
      return;
    }

    final result = await showModalBottomSheet<_TripSelection>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _TripAddressSheet(
        addresses: addresses,
        needBoarding: needBoarding,
        needDropoff: needDropoff,
        initialBoardingId: _boarding?.addressId,
        initialDropoffId: _dropoff?.addressId,
        statusLabel: status.label,
      ),
    );
    if (result == null) return;

    await _saveVote(status, boarding: result.boarding, dropoff: result.dropoff);
  }

  Future<void> _saveVote(AttendanceStatus status, {AddressRef? boarding, AddressRef? dropoff}) async {
    final user = widget.viewModel.currentUser;
    if (user?.salaId == null) return;

    setState(() => _saving = true);
    try {
      final repo = ServiceLocator.getIt<SalaRepository>();
      final data = <String, dynamic>{
        'status': status.name,
        'userName': user!.name,
        'faculdadeId': user.faculdadeId,
        'faculdadeName': user.faculdadeName,
        'updatedAt': DateTime.now().toIso8601String(),
        'boarding': boarding?.toMap(),
        'dropoff': dropoff?.toMap(),
      };
      await repo.saveVote(salaId: user.salaId!, date: _today, userId: user.id, data: data);
      setState(() { _selectedStatus = status; _boarding = boarding; _dropoff = dropoff; });
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
              _buildAttendanceReminder(),
              _buildWelcomeHeader(user.primeiroNome),
              const SizedBox(height: 24),
              _buildInfoCards(user),
              const SizedBox(height: 24),
              _buildAttendanceSection(),
              if (_selectedStatus != null && _selectedStatus != AttendanceStatus.naoVai && _selectedStatus != AttendanceStatus.pendente) ...[
                const SizedBox(height: 16),
                _buildSelectedAddresses(),
              ],
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

  /// Lembrete exibido quando o aluno ainda não marcou chamada no dia.
  /// Aparece a partir das 6h da manhã.
  Widget _buildAttendanceReminder() {
    final hour = DateTime.now().hour;
    final naoPrecisa = _selectedStatus != null &&
        _selectedStatus != AttendanceStatus.pendente;
    if (naoPrecisa || hour < 6) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.warningLight,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Não esqueça de marcar sua chamada hoje!',
              style: TextStyle(
                  color: AppTheme.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ]),
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
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
        ])),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
        ),
      ]),
    );
  }

  Widget _buildInfoCards(dynamic user) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.manageAddresses),
        child: _miniCard(Icons.location_on_rounded, 'Endereços', 'Gerenciar', AppTheme.primary, showChevron: true),
      )),
      const SizedBox(width: 12),
      Expanded(child: _miniCard(Icons.school_rounded, 'Faculdade', user.faculdadeName ?? 'Não definida', AppTheme.accent)),
    ]);
  }

  Widget _miniCard(IconData icon, String label, String value, Color color, {bool showChevron = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppTheme.radiusMd), child: Icon(icon, color: color, size: 18)),
          if (showChevron) ...[const Spacer(), Icon(Icons.chevron_right_rounded, color: AppTheme.grey300, size: 20)],
        ]),
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
      onTap: _saving ? null : () => _startVote(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppTheme.grey50,
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

  Widget _buildSelectedAddresses() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusLg, boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Endereços do trajeto', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        if (_boarding != null)
          _addrRow(Icons.trip_origin_rounded, AppTheme.primary, 'Embarque (ida)', _boarding!),
        if (_boarding != null && _dropoff != null) const SizedBox(height: 8),
        if (_dropoff != null)
          _addrRow(Icons.flag_rounded, AppTheme.accent, 'Desembarque (volta)', _dropoff!),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _saving ? null : () => _startVote(_selectedStatus!),
          icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
          label: const Text('Alterar endereços'),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), padding: const EdgeInsets.symmetric(vertical: 10)),
        )),
      ]),
    );
  }

  Widget _addrRow(IconData icon, Color color, String title, AddressRef ref) {
    return Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: AppTheme.radiusMd), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppTheme.grey500, fontSize: 11)),
        Text('${ref.label}${ref.shortAddress.isNotEmpty ? ' · ${ref.shortAddress}' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]);
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
            decoration: BoxDecoration(color: _liberado ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.grey100, borderRadius: AppTheme.radiusMd),
            child: Icon(_liberado ? Icons.check_circle_rounded : Icons.exit_to_app_rounded, color: _liberado ? AppTheme.success : AppTheme.grey400, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_liberado ? 'Você foi liberado!' : 'Fui liberado da faculdade',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _liberado ? AppTheme.success : AppTheme.grey900)),
            Text(_liberado ? 'O motorista foi notificado' : 'Toque quando sair da faculdade',
              style: TextStyle(color: _liberado ? AppTheme.success.withValues(alpha: 0.8) : AppTheme.grey500, fontSize: 12)),
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

class _TripSelection {
  final AddressRef? boarding;
  final AddressRef? dropoff;
  const _TripSelection({this.boarding, this.dropoff});
}

class _TripAddressSheet extends StatefulWidget {
  final List<StudentAddress> addresses;
  final bool needBoarding;
  final bool needDropoff;
  final String? initialBoardingId;
  final String? initialDropoffId;
  final String statusLabel;
  const _TripAddressSheet({
    required this.addresses,
    required this.needBoarding,
    required this.needDropoff,
    required this.statusLabel,
    this.initialBoardingId,
    this.initialDropoffId,
  });
  @override
  State<_TripAddressSheet> createState() => _TripAddressSheetState();
}

class _TripAddressSheetState extends State<_TripAddressSheet> {
  StudentAddress? _boarding;
  StudentAddress? _dropoff;

  @override
  void initState() {
    super.initState();
    final defaultAddr = _defaultAddress();
    _boarding = _find(widget.initialBoardingId) ?? defaultAddr;
    _dropoff = _find(widget.initialDropoffId) ?? defaultAddr;
  }

  StudentAddress? _defaultAddress() {
    if (widget.addresses.isEmpty) return null;
    for (final a in widget.addresses) {
      if (a.isDefault) return a;
    }
    return widget.addresses.first;
  }

  StudentAddress? _find(String? id) {
    if (id == null) return null;
    for (final a in widget.addresses) {
      if (a.id == id) return a;
    }
    return null;
  }

  AddressRef _toRef(StudentAddress a) => AddressRef(
        addressId: a.id, label: a.label, shortAddress: a.enderecoCurto,
        latitude: a.latitude, longitude: a.longitude,
      );

  void _confirm() {
    Navigator.pop(context, _TripSelection(
      boarding: widget.needBoarding && _boarding != null ? _toRef(_boarding!) : null,
      dropoff: widget.needDropoff && _dropoff != null ? _toRef(_dropoff!) : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.grey300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text(widget.statusLabel, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Escolha os endereços para o trajeto de hoje.', style: TextStyle(color: AppTheme.grey500, fontSize: 13)),
        const SizedBox(height: 20),
        if (widget.needBoarding) ...[
          Row(children: const [
            Icon(Icons.trip_origin_rounded, color: AppTheme.primary, size: 18), SizedBox(width: 8),
            Text('Onde te buscar (ida)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          ...widget.addresses.map((a) => _option(a, selected: _boarding?.id == a.id, onTap: () => setState(() => _boarding = a))),
          const SizedBox(height: 16),
        ],
        if (widget.needDropoff) ...[
          Row(children: const [
            Icon(Icons.flag_rounded, color: AppTheme.accent, size: 18), SizedBox(width: 8),
            Text('Onde te deixar (volta)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          ...widget.addresses.map((a) => _option(a, selected: _dropoff?.id == a.id, onTap: () => setState(() => _dropoff = a))),
          const SizedBox(height: 16),
        ],
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd), elevation: 0),
          child: const Text('Confirmar chamada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        )),
      ])),
    );
  }

  Widget _option(StudentAddress a, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : AppTheme.grey50,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.grey200, width: selected ? 2 : 1),
          borderRadius: AppTheme.radiusMd,
        ),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? AppTheme.primary : AppTheme.grey400, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis)),
              if (a.isDefault) ...[
                const SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), borderRadius: AppTheme.radiusFull),
                  child: const Text('Padrão', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700))),
              ],
            ]),
            if (a.enderecoCurto.isNotEmpty)
              Text(a.enderecoCurto, style: const TextStyle(color: AppTheme.grey500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (!a.hasCoordinates)
              const Text('⚠ Sem coordenadas', style: TextStyle(color: AppTheme.warning, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}
