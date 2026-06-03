// Contrôleur gérant l'état d'authentification (ChangeNotifier)

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── GETTERS ─────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // ─── INITIALISATION ──────────────────────────────────────

  /// Charge l'utilisateur depuis la session sauvegardée
  Future<bool> tryAutoLogin() async {
    _setLoading(true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── REGISTER ────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final error = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return false;
      }
      // Recharger l'utilisateur après inscription
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGIN ───────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final error = await _authService.login(
        email: email,
        password: password,
      );
      if (error != null) {
        _errorMessage = error;
        notifyListeners();
        return false;
      }
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  // ─── LOGOUT ──────────────────────────────────────────────

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ─── HELPERS PRIVÉS ──────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}