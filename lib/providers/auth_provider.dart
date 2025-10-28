import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus { idle, loading, success, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _status = AuthStatus.success;
        notifyListeners();
        return true;
      } else if (user != null && !user.emailVerified) {
        _errorMessage = 'Please verify your email before logging in.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Login failed.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  bool get canResendVerification {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.emailVerified;
  }

  Future<void> resendVerificationLink() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await _authService.sendEmailVerification();
    }
  }

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
