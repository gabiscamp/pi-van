import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/repositories/sala_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class JoinSalaPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const JoinSalaPage({super.key, required this.viewModel});
  @override
  State<JoinSalaPage> createState() => _JoinSalaPageState();
}

class _JoinSalaPageState extends State<JoinSalaPage> {
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinSala() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showError('Digite o código da sala');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final salaRepo = ServiceLocator.getIt<SalaRepository>();
      final user = widget.viewModel.currentUser!;
      final sala = await salaRepo.joinSala(
        studentId: user.id,
        studentName: user.name,
        accessCode: code,
      );

      if (sala == null) {
        _showError('Código de sala inválido');
        return;
      }

      // Atualiza o usuário com o salaId e adiciona à lista de salas (salaIds).
      final newSalaIds = List<String>.from(user.salaIds);
      if (!newSalaIds.contains(sala.id)) newSalaIds.add(sala.id);
      widget.viewModel.updateCurrentUser(user.copyWith(salaId: sala.id, salaIds: newSalaIds));

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.selectFaculdade,
        arguments: {'salaId': sala.id},
      );
    } catch (e) {
      _showError('Erro ao entrar na sala');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
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
                child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),
              const Text('Digite o código\nda sala', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1)),
              const SizedBox(height: 12),
              const Text(
                'Você receberá este código do seu motorista. Depois, escolherá a faculdade que você frequenta.',
                style: TextStyle(color: AppTheme.grey500, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 40),
              const Text('Código da sala', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              AppTextField(controller: _codeCtrl, label: 'Ex: ABC123', hintText: 'ABC123', prefixIcon: Icons.vpn_key_outlined),
              const SizedBox(height: 32),
              AppButton(label: 'Continuar', isLoading: _isLoading, onPressed: _joinSala),
            ],
          ),
        ),
      ),
    );
  }
}
