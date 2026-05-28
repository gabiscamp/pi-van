import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  final String? nextRoute;
  final AuthViewModel viewModel;
  const LoginPage({super.key, this.nextRoute, required this.viewModel});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _doLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) { _showError('Preencha todos os campos'); return; }
    setState(() => _isLoading = true);
    try {
      await widget.viewModel.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      if (!mounted) return;
      if (widget.nextRoute != null) { Navigator.of(context).pushReplacementNamed(widget.nextRoute!); }
      else { final rota = widget.viewModel.redirectRoute; if (rota != null) Navigator.of(context).pushReplacementNamed(rota); }
    } catch (e) { _showError('Email ou senha incorretos'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final email = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusLg),
      title: const Text('Redefinir Senha'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Digite seu e-mail e enviaremos um link para redefinir sua senha.', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
        const SizedBox(height: 16),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          child: const Text('Enviar')),
      ],
    ));

    if (email != null && email.isNotEmpty) {
      try {
        await widget.viewModel.sendPasswordReset(email);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de redefinição enviado! Verifique sua caixa de entrada.'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating));
      } catch (e) {
        if (mounted) _showError('Erro ao enviar email. Verifique o endereço.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(onTap: () => Navigator.of(context).pop(),
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.white, borderRadius: AppTheme.radiusMd, border: Border.all(color: AppTheme.grey200)),
              child: const Icon(Icons.arrow_back_rounded, size: 20))),
          const SizedBox(height: 32),
          Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28)),
          const SizedBox(height: 24),
          const Text('Bem-vindo de volta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Faça login para acessar sua conta', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
          const SizedBox(height: 40),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          AppTextField(controller: _emailCtrl, label: 'Digite seu email', hintText: 'exemplo@email.com', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
          const SizedBox(height: 20),
          const Text('Senha', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          AppTextField(controller: _passwordCtrl, label: 'Digite sua senha', obscureText: true, prefixIcon: Icons.lock_outlined),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: GestureDetector(onTap: _forgotPassword,
            child: const Text('Esqueci minha senha', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)))),
          const SizedBox(height: 24),
          AppButton(label: 'Entrar', isLoading: _isLoading, onPressed: _doLogin),
          const SizedBox(height: 20),
          Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Não tem conta? ', style: TextStyle(color: AppTheme.grey500)),
            GestureDetector(onTap: () => Navigator.of(context).pushNamed(AppRoutes.register),
              child: const Text('Cadastre-se', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
          ])),
        ]),
      )),
    );
  }
}
