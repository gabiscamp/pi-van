import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pi_van/core/via_cep_service.dart';

import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  AuthViewModel({
    required this.loginUseCase,
    required this.registerUseCase,
  });

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _currentUser = await loginUseCase.execute(
        email: email,
        password: password,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required Role role,
    required String logradouro,
    required String numero,
    required String complemento,
    required String bairro,
    required String cep,
    required String localidade,
    required String uf,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _currentUser = await registerUseCase.execute(
        name: name,
        email: email,
        password: password,
        role: role,
        logradouro: logradouro,
        numero: numero,
        complemento: complemento,
        bairro: bairro,
        cep: cep,
        localidade: localidade,
        uf: uf,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  // Crie uma instância do serviço no topo ou passe pelo construtor (aqui vamos instanciar direto pela simplicidade)
  final _viaCepService = ViaCepService();

  // ... (seus códigos de login e register continuam aqui) ...

  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    // Você pode até ativar o isLoading aqui se quiser mostrar um ícone de carregamento na tela!
    return await _viaCepService.buscarEndereco(cep);
  }
  // --- COLE ISTO ANTES DA ÚLTIMA CHAVE DA CLASSE ---
  
  Future<Map<String, dynamic>?> buscarEndereco(String cep) async {
    // Importe o pacote http se ainda não tiver feito
  

    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length != 8) return null;

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('erro')) return null; 
        return data;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
