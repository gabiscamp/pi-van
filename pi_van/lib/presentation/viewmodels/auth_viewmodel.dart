import 'package:flutter/foundation.dart';
import 'package:pi_van/core/via_cep_service.dart';
import 'package:pi_van/core/routing/app_router.dart';

import '../../domain/entities/user.dart';
import '../../domain/enums/role_enum.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final AuthRepository authRepository;

  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  AuthViewModel({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.authRepository,
  });

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  Role? get currentRole => _currentUser?.role;

  String? get redirectRoute {
    if (_currentUser == null) return null;
    switch (_currentUser!.role) {
      case Role.motorista:
        return AppRoutes.driverShell;
      case Role.estudante:
        return AppRoutes.studentShell;
    }
  }

  /// Verifica se o usuário já completou o setup (tem sala)
  bool get needsSetup => _currentUser?.salaId == null;

  /// Tenta recuperar sessão ativa do Firebase
  Future<bool> tryAutoLogin() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _error = null;
    try {
      _currentUser = await loginUseCase.execute(email: email, password: password);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String name, required String email, required String password,
    required Role role, required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _currentUser = await registerUseCase.execute(
        name: name, email: email, password: password, role: role,
        logradouro: logradouro, numero: numero, complemento: complemento,
        bairro: bairro, cep: cep, localidade: localidade, uf: uf,
        latitude: latitude, longitude: longitude,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza dados do usuário (ex: depois de escolher faculdade, salaId, etc)
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await authRepository.logout(); // AGORA chama o Firebase signOut
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  final _viaCepService = ViaCepService();
  Future<Map<String, dynamic>?> buscarCep(String cep) =>
      _viaCepService.buscarEndereco(cep);
}
