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

  AuthViewModel({required this.loginUseCase, required this.registerUseCase, required this.authRepository});

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  Role? get currentRole => _currentUser?.role;

  String? get redirectRoute {
    if (_currentUser == null) return null;
    return _currentUser!.role == Role.motorista ? AppRoutes.driverShell : AppRoutes.studentShell;
  }

  bool get needsSetup => _currentUser?.salaId == null;

  Future<bool> tryAutoLogin() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) { _currentUser = user; notifyListeners(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true); _error = null;
    try {
      _currentUser = await loginUseCase.execute(email: email, password: password);
      notifyListeners();
    } catch (e) { _error = e.toString(); rethrow; }
    finally { _setLoading(false); }
  }

  Future<void> register({
    required String name, required String email, required String password,
    String phone = '', required Role role,
    required String logradouro, required String numero,
    required String complemento, required String bairro, required String cep,
    required String localidade, required String uf,
    double? latitude, double? longitude,
  }) async {
    _setLoading(true); _error = null;
    try {
      _currentUser = await registerUseCase.execute(
        name: name, email: email, password: password, phone: phone, role: role,
        logradouro: logradouro, numero: numero, complemento: complemento,
        bairro: bairro, cep: cep, localidade: localidade, uf: uf,
        latitude: latitude, longitude: longitude,
      );
      notifyListeners();
    } catch (e) { _error = e.toString(); rethrow; }
    finally { _setLoading(false); }
  }

  void updateCurrentUser(User user) { _currentUser = user; notifyListeners(); }

  /// Muda a sala ativa em memória (sem persistir no Firestore)
  void selectSala(String salaId) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(salaId: salaId);
    notifyListeners();
  }

  /// Recarrega o usuário do Firestore (atualiza salaIds, faculdade, etc.)
  Future<void> reloadUser() async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) { _currentUser = user; notifyListeners(); }
    } catch (_) {}
  }

  Future<void> logout() async {
    await authRepository.logout();
    _currentUser = null; _error = null; notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    await authRepository.sendPasswordResetEmail(email);
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  final _viaCepService = ViaCepService();
  Future<Map<String, dynamic>?> buscarCep(String cep) => _viaCepService.buscarEndereco(cep);
}
