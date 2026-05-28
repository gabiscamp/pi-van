import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../domain/enums/role_enum.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  final AuthViewModel viewModel;
  const RegisterPage({super.key, required this.viewModel});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _ruaCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _ufCtrl = TextEditingController();
  final _complementoCtrl = TextEditingController();

  String _role = 'estudante';
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in [_nameCtrl, _emailCtrl, _phoneCtrl, _passwordCtrl, _confirmCtrl, _cepCtrl, _ruaCtrl, _numeroCtrl, _bairroCtrl, _cidadeCtrl, _ufCtrl, _complementoCtrl]) {
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty || _confirmCtrl.text.isEmpty) {
      _showError('Preencha todos os campos');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showError('As senhas não conferem');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('A senha deve ter no mínimo 6 caracteres');
      return;
    }
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _previousPage() {
    _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _cadastrar() async {
    if (_cepCtrl.text.isEmpty || _ruaCtrl.text.isEmpty || _bairroCtrl.text.isEmpty || _cidadeCtrl.text.isEmpty || _ufCtrl.text.isEmpty) {
      _showError('Preencha os campos de endereço obrigatórios (rua, bairro, cidade, UF)');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Geocodificar endereço para obter lat/lng
      double? lat, lng;
      try {
        final geo = ServiceLocator.getIt<GeocodingService>();
        final result = await geo.geocodeAddress(
          rua: _ruaCtrl.text.trim(), numero: _numeroCtrl.text.trim(),
          bairro: _bairroCtrl.text.trim(), cidade: _cidadeCtrl.text.trim(), uf: _ufCtrl.text.trim(),
        );
        if (result != null) { lat = result.lat; lng = result.lng; }
      } catch (_) {}

      await widget.viewModel.register(
        name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim(),
        role: _role == 'motorista' ? Role.motorista : Role.estudante,
        logradouro: _ruaCtrl.text.trim(), numero: _numeroCtrl.text.trim(),
        complemento: _complementoCtrl.text.trim(), bairro: _bairroCtrl.text.trim(),
        cep: _cepCtrl.text.trim(), localidade: _cidadeCtrl.text.trim(), uf: _ufCtrl.text.trim(),
        latitude: lat, longitude: lng,
      );
      if (!mounted) return;

      final geoMsg = (lat != null && lng != null)
          ? 'Cadastro realizado! Localização encontrada ✓'
          : 'Cadastro realizado! (Endereço sem coordenadas — verifique o número)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(geoMsg), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)),
      );
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        final rota = widget.viewModel.redirectRoute;
        Navigator.of(context).pushReplacementNamed(rota ?? AppRoutes.login);
      }
    } catch (e) {
      _showError('Erro ao cadastrar: ${e.toString()}');
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
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [_buildPage1(), _buildPage2()],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= _currentPage ? AppTheme.primary : AppTheme.grey200,
                ),
              ),
            )),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(child: AppButton(label: 'Voltar', isOutlined: true, onPressed: _previousPage)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AppButton(
                  label: _currentPage == 0 ? 'Próximo' : 'Cadastrar',
                  isLoading: _isLoading,
                  onPressed: _currentPage == 0 ? _nextPage : _cadastrar,
                ),
              ),
            ],
          ),
          if (_currentPage == 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem conta? ', style: TextStyle(color: AppTheme.grey500)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.login),
                  child: const Text('Entrar', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
          const SizedBox(height: 24),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Criar conta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Preencha seus dados pessoais', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
          const SizedBox(height: 28),
          _label('Nome completo'),
          AppTextField(controller: _nameCtrl, label: 'Seu nome', prefixIcon: Icons.person_outlined),
          const SizedBox(height: 16),
          _label('Email'),
          AppTextField(controller: _emailCtrl, label: 'seu@email.com', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined),
          const SizedBox(height: 16),
          _label('Telefone'),
          AppTextField(controller: _phoneCtrl, label: '(31) 99999-9999', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined),
          const SizedBox(height: 16),
          _label('Senha'),
          AppTextField(controller: _passwordCtrl, label: 'Mínimo 6 caracteres', obscureText: true, prefixIcon: Icons.lock_outlined),
          const SizedBox(height: 16),
          _label('Confirmar senha'),
          AppTextField(controller: _confirmCtrl, label: 'Repita a senha', obscureText: true, prefixIcon: Icons.lock_outlined),
          const SizedBox(height: 24),
          const Text('Eu sou...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _RoleOption(
                label: 'Estudante', icon: Icons.school_rounded,
                selected: _role == 'estudante',
                onTap: () => setState(() => _role = 'estudante'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _RoleOption(
                label: 'Motorista', icon: Icons.directions_bus_rounded,
                selected: _role == 'motorista',
                onTap: () => setState(() => _role = 'motorista'),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Endereço de casa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Usaremos para calcular as rotas otimizadas', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
          const SizedBox(height: 28),
          _label('CEP'),
          AppTextField(
            controller: _cepCtrl, label: '00000-000', keyboardType: TextInputType.number, prefixIcon: Icons.location_on_outlined,
            onChanged: (valor) async {
              final cep = valor.replaceAll(RegExp(r'[^0-9]'), '');
              if (cep.length == 8) {
                final endereco = await widget.viewModel.buscarCep(cep);
                if (endereco != null) {
                  _ruaCtrl.text = endereco['logradouro'] ?? '';
                  _bairroCtrl.text = endereco['bairro'] ?? '';
                  _cidadeCtrl.text = endereco['localidade'] ?? '';
                  _ufCtrl.text = endereco['uf'] ?? '';
                  if (mounted) FocusScope.of(context).nextFocus();
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _label('Rua'),
          AppTextField(controller: _ruaCtrl, label: 'Nome da rua'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Número'), AppTextField(controller: _numeroCtrl, label: '000', keyboardType: TextInputType.number)])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Bairro'), AppTextField(controller: _bairroCtrl, label: 'Bairro')])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Cidade'), AppTextField(controller: _cidadeCtrl, label: 'Cidade')])),
            const SizedBox(width: 12),
            SizedBox(width: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('UF'), AppTextField(controller: _ufCtrl, label: 'MG')])),
          ]),
          const SizedBox(height: 16),
          _label('Complemento (opcional)'),
          AppTextField(controller: _complementoCtrl, label: 'Apto, bloco...'),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
  );
}

class _RoleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _RoleOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLight : AppTheme.white,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.grey200, width: selected ? 2 : 1),
          borderRadius: AppTheme.radiusMd,
        ),
        child: Column(children: [
          Icon(icon, color: selected ? AppTheme.primary : AppTheme.grey400, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? AppTheme.primary : AppTheme.grey600)),
        ]),
      ),
    );
  }
}
