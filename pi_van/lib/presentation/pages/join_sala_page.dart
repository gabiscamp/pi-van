import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';

class JoinSalaPage extends StatefulWidget {
  const JoinSalaPage({super.key});

  @override
  State<JoinSalaPage> createState() => _JoinSalaPageState();
}

class _JoinSalaPageState extends State<JoinSalaPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 60),
                _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          'Digite o código da sala',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Você receberá este código do seu motorista. '
          'Depois, escolherá a faculdade.',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Código da sala',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: _codeController,
          label: 'Ex: VAN001',
          hintText: 'VAN001',
          prefixIcon: Icons.vpn_key_outlined,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Continuar',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.selectFaculdade);
          },
        ),
      ],
    );
  }
}
