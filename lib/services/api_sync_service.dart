// ─────────────────────────────────────────────────────────────────────────────
// ApiSyncService — Synchronisation avec json-server (API REST locale)
//
// RÔLE : Envoyer les données vers json-server EN PARALLÈLE de SQLite.
//        Ce service ne REMPLACE PAS DatabaseService.
//        SQLite reste la source principale (offline-first).
//        Si le serveur est inaccessible, l'app continue de fonctionner
//        normalement grâce à SQLite.
//
// ARCHITECTURE :
//   Contrôleur → DatabaseService (SQLite)  [toujours, immédiat]
//             → ApiSyncService  (API)      [en arrière-plan, non-bloquant]
//
// URLS json-server :
//   Émulateur Android  → http://10.0.2.2:3000
//   iOS / Web          → http://localhost:3000
//   Appareil physique  → http://<IP_PC>:3000
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class ApiSyncService {
  // ─── SINGLETON ───────────────────────────────────────────
  static final ApiSyncService _instance = ApiSyncService._internal();
  factory ApiSyncService() => _instance;
  ApiSyncService._internal();

  // ─── CONFIGURATION ───────────────────────────────────────

  /// URL de base du serveur json-server
  /// Changer selon la cible (voir commentaire en haut du fichier)
  static const String _baseUrl = 'http://10.0.2.2:3000';

  /// Timeout des requêtes HTTP (5 secondes)
  static const Duration _timeout = Duration(seconds: 5);

  // ─── HELPER INTERNE ──────────────────────────────────────

  /// Retire la clé 'id' si elle est null (laisser json-server l'assigner)
  Map<String, dynamic> _cleanMap(Map<String, dynamic> map) {
    final m = Map<String, dynamic>.from(map);
    if (m['id'] == null) m.remove('id');
    // Retirer spentAmount car c'est un champ calculé, pas stocké
    m.remove('spentAmount');
    return m;
  }

  // ─── STATUT DU SERVEUR ───────────────────────────────────

  /// Retourne true si json-server est joignable
  Future<bool> isServerAvailable() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // TRANSACTIONS
  // Endpoints :
  //   GET    /transactions?userId=X  → lire les transactions
  //   POST   /transactions           → ajouter
  //   PUT    /transactions/:id       → modifier
  //   DELETE /transactions/:id       → supprimer
  // ─────────────────────────────────────────────────────────

  /// Envoie une nouvelle transaction au serveur (POST)
  Future<void> pushTransaction(TransactionModel transaction) async {
    try {
      final body = _cleanMap(transaction.toMap());
      final response = await http
          .post(
            Uri.parse('$_baseUrl/transactions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[API ✓] Transaction id=${transaction.id} envoyée');
      } else {
        debugPrint('[API ✗] Push transaction : ${response.statusCode}');
      }
    } catch (e) {
      // Non bloquant — SQLite a déjà sauvegardé les données
      debugPrint('[API ✗] Serveur inaccessible (transaction sauvegardée localement)');
    }
  }

  /// Met à jour une transaction sur le serveur (PUT)
  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id == null) return;
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/transactions/${transaction.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(transaction.toMap()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('[API ✓] Transaction id=${transaction.id} mise à jour');
      } else {
        debugPrint('[API ✗] Update transaction : ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API ✗] Erreur update transaction : $e');
    }
  }

  /// Supprime une transaction sur le serveur (DELETE)
  Future<void> deleteTransaction(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/transactions/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[API ✓] Transaction id=$id supprimée');
      } else {
        debugPrint('[API ✗] Delete transaction : ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API ✗] Erreur delete transaction : $e');
    }
  }

  /// Récupère les transactions d'un utilisateur depuis le serveur (GET)
  Future<List<TransactionModel>> fetchTransactions(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/transactions?userId=$userId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TransactionModel.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[API ✗] Fetch transactions : $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUDGETS
  // Endpoints :
  //   GET    /budgets?userId=X  → lire les budgets
  //   POST   /budgets           → ajouter
  //   DELETE /budgets/:id       → supprimer
  // ─────────────────────────────────────────────────────────

  /// Envoie un nouveau budget au serveur (POST)
  Future<void> pushBudget(BudgetModel budget) async {
    try {
      final body = _cleanMap(budget.toMap());
      final response = await http
          .post(
            Uri.parse('$_baseUrl/budgets'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[API ✓] Budget id=${budget.id} envoyé');
      } else {
        debugPrint('[API ✗] Push budget : ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API ✗] Serveur inaccessible (budget sauvegardé localement)');
    }
  }

  /// Supprime un budget sur le serveur (DELETE)
  Future<void> deleteBudget(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/budgets/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('[API ✓] Budget id=$id supprimé');
      } else {
        debugPrint('[API ✗] Delete budget : ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API ✗] Erreur delete budget : $e');
    }
  }

  /// Récupère les budgets d'un utilisateur depuis le serveur (GET)
  Future<List<BudgetModel>> fetchBudgets(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/budgets?userId=$userId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => BudgetModel.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[API ✗] Fetch budgets : $e');
      return [];
    }
  }
}
