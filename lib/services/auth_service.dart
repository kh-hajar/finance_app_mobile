// Service gérant l'authentification : hashage password, login, register

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import 'database_service.dart';
import 'pref_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _db = DatabaseService();
  final PrefService _prefs = PrefService();

  /// Hash le mot de passe avec SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Enregistre un nouvel utilisateur
  /// Retourne null si succès, sinon un message d'erreur
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Vérifier si l'email existe déjà
      final existing = await _db.getUserByEmail(email);
      if (existing != null) {
        return 'Un compte avec cet email existe déjà.';
      }

      // Créer l'utilisateur
      final user = UserModel(
        name: name,
        email: email,
        password: hashPassword(password),
      );

      final userId = await _db.insertUser(user);

      // Créer les catégories par défaut
      final defaultCats = CategoryModel.defaultCategories(userId);
      for (final cat in defaultCats) {
        await _db.insertCategory(cat);
      }

      // Sauvegarder la session
      await _prefs.saveUserId(userId);
      return null; // succès
    } catch (e) {
      return 'Erreur lors de l\'inscription : $e';
    }
  }

  /// Connecte un utilisateur existant
  /// Retourne null si succès, sinon un message d'erreur
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        return 'Aucun compte trouvé avec cet email.';
      }

      if (user.password != hashPassword(password)) {
        return 'Mot de passe incorrect.';
      }

      await _prefs.saveUserId(user.id!);
      return null; // succès
    } catch (e) {
      return 'Erreur lors de la connexion : $e';
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    await _prefs.clearSession();
  }

  /// Retourne l'utilisateur connecté ou null
  Future<UserModel?> getCurrentUser() async {
    final userId = await _prefs.getUserId();
    if (userId == null) return null;
    return await _db.getUserById(userId);
  }

  /// Vérifie si une session active existe
  Future<bool> isLoggedIn() async {
    final userId = await _prefs.getUserId();
    return userId != null;
  }
}