import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/faculdade.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class SelectFaculdadePage extends StatefulWidget {
  final AuthViewModel viewModel;
  final String salaId;
  const SelectFaculdadePage({super.key, required this.viewModel, required this.salaId});
  @override
  State<SelectFaculdadePage> createState() => _SelectFaculdadePageState();
}

class _SelectFaculdadePageState extends State<SelectFaculdadePage> {
  List<Faculdade> _faculdades = [];
  Faculdade? _selected;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFaculdades();
  }

  Future<void> _loadFaculdades() async {
    try {
      final salaRepo = ServiceLocator.getIt<SalaRepository>();
      final facs = await salaRepo.getFaculdades(widget.salaId);
      setState(() { _faculdades = facs; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final user = widget.viewModel.currentUser!;
      final updatedUser = user.copyWith(faculdadeId: _selected!.id, faculdadeName: _selected!.name);
      final authRepo = ServiceLocator.getIt<AuthRepository>();
      await authRepo.updateUser(updatedUser);
      widget.viewModel.updateCurrentUser(updatedUser);

      // Também grava a faculdade no documento do aluno dentro da sala,
      // para que o motorista a veja mesmo sem chamada confirmada.
      try {
        await ServiceLocator.getIt<SalaRepository>().setStudentFaculdade(
          salaId: widget.salaId,
          studentId: user.id,
          faculdadeId: _selected!.id,
          faculdadeName: _selected!.name,
        );
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.studentShell, (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 24),
                    const Text('Escolha sua\nfaculdade', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1)),
                    const SizedBox(height: 12),
                    const Text('Selecione a instituição que você frequenta entre as faculdades atendidas pelo motorista.',
                      style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 32),
                    if (_faculdades.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: AppTheme.radiusLg),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 32),
                            SizedBox(height: 12),
                            Text('Nenhuma faculdade cadastrada', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.warning)),
                            SizedBox(height: 4),
                            Text('O motorista ainda não adicionou faculdades à sala.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.grey600, fontSize: 13)),
                          ],
                        ),
                      )
                    else
                      ..._faculdades.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _faculdadeCard(f),
                      )),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Confirmar',
                      isLoading: _saving,
                      onPressed: _selected != null ? _confirm : null,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _faculdadeCard(Faculdade fac) {
    final isSelected = _selected?.id == fac.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = fac),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.grey200, width: isSelected ? 2 : 1),
          borderRadius: AppTheme.radiusLg,
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))] : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.grey300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fac.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  if (fac.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(fac.address, style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Icon(Icons.school_rounded, color: isSelected ? AppTheme.primary : AppTheme.grey300, size: 20),
          ],
        ),
      ),
    );
  }
}
