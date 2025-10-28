import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.signUp(email, password);
      if (result != null) {
        await _authService.sendEmailVerification();
        _status = AuthStatus.success;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Registration failed.';
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void idle() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
