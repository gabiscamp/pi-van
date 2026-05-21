import 'package:flutter/foundation.dart';
import 'package:pi_van/core/via_cep_service.dart';
import 'package:pi_van/core/routing/app_router.dart'; // ← ADICIONADO

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
  Role? get currentRole => _currentUser?.role; // ← ADICIONADO

  // ← ADICIONADO
  String? get redirectRoute {
    switch (_currentUser?.role) {
      case Role.motorista:
        return AppRoutes.homeDriver;
      case Role.estudante:
        return AppRoutes.joinSala;
      default:
        return null;
    }
  }

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
      notifyListeners(); // ← ADICIONADO
    } catch (e) {
      _error = e.toString();
      rethrow;
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
      notifyListeners(); // ← ADICIONADO
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ← ADICIONADO
  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  final _viaCepService = ViaCepService();

  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    return await _viaCepService.buscarEndereco(cep);
  }
}