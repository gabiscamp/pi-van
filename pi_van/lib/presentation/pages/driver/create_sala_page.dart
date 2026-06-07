import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class CreateSalaPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const CreateSalaPage({super.key, required this.viewModel});
  @override
  State<CreateSalaPage> createState() => _CreateSalaPageState();
}

class _CreateSalaPageState extends State<CreateSalaPage> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _createdCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSala() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para a sala'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = widget.viewModel.currentUser!;
      final salaRepo = ServiceLocator.getIt<SalaRepository>();
      final sala = await salaRepo.createSala(
        name: _nameCtrl.text.trim(),
        driverId: user.id,
        driverName: user.name,
      );

      // Atualiza salaId e salaIds no Firestore
      final authRepo = ServiceLocator.getIt<AuthRepository>();
      final newSalaIds = List<String>.from(user.salaIds);
      if (!newSalaIds.contains(sala.id)) newSalaIds.add(sala.id);
      final updatedUser = user.copyWith(salaId: sala.id, salaIds: newSalaIds);
      await authRepo.updateUser(updatedUser);
      widget.viewModel.updateCurrentUser(updatedUser);

      if (!mounted) return;
      setState(() => _createdCode = sala.accessCode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: _createdCode != null ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, border: Border.all(color: AppTheme.grey200)),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_home_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        const Text('Criar sua sala', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        const Text(
          'Crie uma sala e compartilhe o código com seus alunos. Depois, adicione as faculdades atendidas.',
          style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 40),
        const Text('Nome da sala', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        AppTextField(controller: _nameCtrl, label: 'Ex: Van do Ricardo - BH', prefixIcon: Icons.meeting_room_outlined),
        const SizedBox(height: 32),
        AppButton(label: 'Criar Sala', isLoading: _isLoading, onPressed: _createSala),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 44),
        ),
        const SizedBox(height: 24),
        const Text('Sala criada!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text(
          'Compartilhe o código abaixo com seus alunos para que eles entrem na sala.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        // Code card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: AppTheme.radiusXl,
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Column(
            children: [
              Text('Código de acesso', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
              const SizedBox(height: 12),
              Text(_createdCode!, style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 8)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _createdCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: AppTheme.radiusFull),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Copiar código', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Next step
        AppButton(
          label: 'Adicionar Faculdades',
          icon: Icons.school_rounded,
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.manageFaculdades),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.driverShell, (r) => false),
          child: const Text('Ir para o painel', style: TextStyle(color: AppTheme.grey500)),
        ),
      ],
    );
  }
}
