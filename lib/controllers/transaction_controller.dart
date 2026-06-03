// Contrôleur gérant toutes les opérations CRUD sur les transactions

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/api_sync_service.dart';

class TransactionController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  // Service API REST (json-server) — travaille en parallèle de SQLite
  final ApiSyncService _api = ApiSyncService();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Filtre actuel
  String _filterType = 'all'; // 'all', 'income', 'expense'
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;

  // ─── GETTERS ─────────────────────────────────────────────

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterType => _filterType;
  int get filterMonth => _filterMonth;
  int get filterYear => _filterYear;

  /// Transactions filtrées selon le type sélectionné
  List<TransactionModel> get filteredTransactions {
    if (_filterType == 'all') return _transactions;
    return _transactions.where((t) => t.type == _filterType).toList();
  }

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  // ─── CHARGEMENT ──────────────────────────────────────────

  Future<void> loadData(int userId) async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadTransactions(userId),
        _loadCategories(userId),
      ]);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadTransactions(int userId) async {
    _transactions = await _db.getTransactionsByUser(
      userId,
      month: _filterMonth,
      year: _filterYear,
    );
  }

  Future<void> _loadCategories(int userId) async {
    _categories = await _db.getCategoriesByUser(userId);
  }

  // ─── CRUD TRANSACTIONS ───────────────────────────────────

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      // 1️⃣ SQLite d'abord — immédiat, fonctionne hors-ligne
      final id = await _db.insertTransaction(transaction);
      // 2️⃣ Sync vers json-server en arrière-plan — non bloquant
      _api.pushTransaction(transaction.copyWith(id: id)).catchError((_) {});
      await _loadTransactions(transaction.userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de l\'ajout : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      // 1️⃣ SQLite d'abord
      await _db.updateTransaction(transaction);
      // 2️⃣ Sync API en arrière-plan
      _api.updateTransaction(transaction).catchError((_) {});
      await _loadTransactions(transaction.userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la modification : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id, int userId) async {
    try {
      // 1️⃣ SQLite d'abord
      await _db.deleteTransaction(id);
      // 2️⃣ Sync API en arrière-plan
      _api.deleteTransaction(id).catchError((_) {});
      await _loadTransactions(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur lors de la suppression : $e';
      notifyListeners();
      return false;
    }
  }

  // ─── STATISTIQUES ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getExpensesByCategory(
      int userId) async {
    return await _db.getExpensesByCategory(
        userId, _filterMonth, _filterYear);
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(int userId) async {
    return await _db.getMonthlyStats(userId, 6);
  }

  // ─── FILTRES ─────────────────────────────────────────────

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> setMonthFilter(int userId, int month, int year) async {
    _filterMonth = month;
    _filterYear = year;
    await _loadTransactions(userId);
    notifyListeners();
  }

  // ─── CATÉGORIES ──────────────────────────────────────────

  List<CategoryModel> getCategoriesByType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  Future<bool> addCategory(CategoryModel category) async {
    try {
      await _db.insertCategory(category);
      await _loadCategories(category.userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id, int userId) async {
    try {
      await _db.deleteCategory(id);
      await _loadCategories(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur : $e';
      notifyListeners();
      return false;
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
