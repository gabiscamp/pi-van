import 'package:flutter/material.dart';
import 'package:pi_van/presentation/viewmodels/auth_viewmodel.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  final String? nextRoute;
  final AuthViewModel viewModel;
  const LoginPage({super.key, this.nextRoute, required this.viewModel});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _role = 'estudante';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bem-vindo de volta',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Faça login para acessar sua conta',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _emailController,
          label: 'Digite seu email',
          hintText: 'exemplo@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        const Text(
          'Senha',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _passwordController,
          label: 'Digite sua senha',
          obscureText: true,
          prefixIcon: Icons.lock_outlined,
        ),
        const SizedBox(height: 20),
        const Text(
          'Você é',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _role,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(
                value: 'estudante',
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Estudante'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'motorista',
                child: Row(
                  children: [
                    Icon(Icons.directions_bus_filled, size: 20),
                    SizedBox(width: 8),
                    Text('Motorista'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _role = value;
              });
            },
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Entrar',
          onPressed: () async {
            try {
              await widget.viewModel.login(
                email: _emailController.text,
                password: _passwordController.text,
              );

              final rota = widget.viewModel.redirectRoute;
              if (rota != null && mounted) {
                Navigator.of(context).pushReplacementNamed(rota);
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Email ou senha incorretos')),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Não tem conta? '),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.register);
                },
                child: const Text(
                  'Cadastre-se',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
