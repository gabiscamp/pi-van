import 'package:flutter/foundation.dart';

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
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _currentUser = await registerUseCase.execute(
        name: name,
        email: email,
        password: password,
        role: role,
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
}
