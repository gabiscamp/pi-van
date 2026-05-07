import 'package:flutter/material.dart';

import '../../core/routing/app_router.dart';
import '../widgets/app_button.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();

  String _role = 'estudante';
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _cepController.dispose();
    _complementoController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: List.generate(2, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: index <= _currentPage
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: AppButton(
                            label: 'Voltar',
                            isOutlined: true,
                            onPressed: _previousPage,
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: _currentPage == 0 ? 'Próximo' : 'Cadastrar',
                          onPressed: _currentPage == 0
                              ? _nextPage
                              : () {
                                  Navigator.of(context)
                                      .pushReplacementNamed(AppRoutes.login);
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          const Text(
            'Dados pessoais',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nome completo',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _nameController,
            label: 'Seu nome',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          const Text(
            'Email',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _emailController,
            label: 'seu.email@exemplo.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          const Text(
            'Senha',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _passwordController,
            label: 'Mínimo 6 caracteres',
            obscureText: true,
            prefixIcon: Icons.lock_outlined,
          ),
          const SizedBox(height: 16),
          const Text(
            'Confirmar senha',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _confirmController,
            label: 'Confirme sua senha',
            obscureText: true,
            prefixIcon: Icons.lock_outlined,
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Endereço de casa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Usaremos para otimizar as rotas',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Text(
            'CEP',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _cepController,
            label: '00000-000',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          const Text(
            'Rua',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _ruaController,
            label: 'Nome da rua',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Número',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _numeroController,
                      label: '000',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bairro',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _bairroController,
                      label: 'Bairro',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cidade',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _cidadeController,
                      label: 'Cidade',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UF',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _ufController,
                      label: 'SP',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Complemento (opcional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _complementoController,
            label: 'Apto, complemento...',
          ),
        ],
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
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 20),
        const Text(
          'Crie sua conta',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Junte-se a nossa comunidade',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
      ],
    );
  }
}
