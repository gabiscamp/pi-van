import 'package:flutter/material.dart';

// Verifique se os caminhos dos imports abaixo estão corretos no seu projeto!
import '../../domain/enums/role_enum.dart'; 
import '../viewmodels/auth_viewmodel.dart'; 

class RegisterPage extends StatefulWidget {
  final AuthViewModel viewModel;

  const RegisterPage({super.key, required this.viewModel});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores para capturar os textos que o usuário digitar
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // O tipo de usuário padrão (inicia como ESTUDANTE)
  Role _selectedRole = Role.estudante;

  @override
  void dispose() {
    // É uma boa prática limpar os controladores quando a tela for fechada
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O ListenableBuilder escuta as mudanças no AuthViewModel (ex: isLoading, error)
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Criar Conta'),
          ),
          body: SingleChildScrollView( // Evita erro de tela cortada com o teclado aberto
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // --- CAMPO NOME ---
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // --- CAMPO E-MAIL ---
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // --- CAMPO SENHA ---
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // Oculta a senha
                ),
                const SizedBox(height: 16),

                // --- SELEÇÃO DE PERFIL ---
                DropdownButtonFormField<Role>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Você é?',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: Role.estudante, 
                      child: Text('Estudante'),
                    ),
                    DropdownMenuItem(
                      value: Role.motorista, 
                      child: Text('Motorista'),
                    ),
                  ],
                  onChanged: (Role? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // --- MENSAGEM DE ERRO (Visível apenas se houver falha) ---
                if (widget.viewModel.error != null) ...[
                  Text(
                    widget.viewModel.error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // --- BOTÃO CADASTRAR ---
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // Se estiver carregando, o botão fica desativado (null)
                  onPressed: widget.viewModel.isLoading 
                      ? null 
                      : () async {
                          // Aciona a função de registro do seu ViewModel
                          await widget.viewModel.register(
                            name: _nameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            role: _selectedRole,
                          );

                          // Se após tentar registrar o erro continuar nulo, foi sucesso!
                          if (widget.viewModel.error == null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cadastro realizado com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Aqui, futuramente, você pode colocar:
                            // Navigator.pop(context); // Para voltar à tela de Login
                          }
                        },
                  child: widget.viewModel.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('CADASTRAR', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}