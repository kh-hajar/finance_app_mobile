// Contrôleur gérant les budgets mensuels par catégorie

import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';
import '../services/api_sync_service.dart';
import '../services/notification_service.dart';
import 'notification_controller.dart';

class BudgetController extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  // Service API REST (json-server) — travaille en parallèle de SQLite
  final ApiSyncService _api = ApiSyncService();
  final NotificationService _notif = NotificationService();

  // Suivi des budgets déjà notifiés (évite les doublons)
  final Set<int> _notifiedExceeded = {};
  final Set<int> _notifiedWarning = {};

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  // ─── GETTERS ─────────────────────────────────────────────

  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get month => _month;
  int get year => _year;

  /// Budgets dépassés
  List<BudgetModel> get overBudgets =>
      _budgets.where((b) => b.isOverBudget).toList();

  // ─── CHARGEMENT ──────────────────────────────────────────

  Future<void> loadBudgets(int userId, {int? month, int? year}) async {
    _month = month ?? _month;
    _year = year ?? _year;
    _setLoading(true);
    try {
      final rawBudgets =
          await _db.getBudgetsByMonth(userId, _month, _year);

      // Récupérer toutes les dépenses par catégorie en une seule requête
      final categorySpentList =
          await _db.getExpensesByCategory(userId, _month, _year);

      // Construire un map categoryId -> montant dépensé
      final spentMap = <int, double>{};
      for (final item in categorySpentList) {
        spentMap[item['categoryId'] as int] =
            (item['total'] as num).toDouble();
      }

      // Enrichir chaque budget avec son montant dépensé réel
      _budgets = rawBudgets.map((b) {
        final spentAmount = spentMap[b.categoryId] ?? 0.0;
        return b.copyWith(spentAmount: spentAmount);
      }).toList();

      // Vérifier les dépassements et envoyer des notifications
      _checkBudgetAlerts(userId);
    } finally {
      _setLoading(false);
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────

  Future<bool> addBudget(BudgetModel budget) async {
    try {
      // 1️⃣ SQLite d'abord — immédiat, fonctionne hors-ligne
      final id = await _db.insertBudget(budget);
      // 2️⃣ Sync vers json-server en arrière-plan — non bloquant
      _api.pushBudget(budget.copyWith(id: id)).catchError((_) {});
      await loadBudgets(budget.userId);
      return true;
    } catch (e) {
      _error = 'Erreur : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBudget(BudgetModel budget) async {
    try {
      await _db.updateBudget(budget);
      await loadBudgets(budget.userId);
      return true;
    } catch (e) {
      _error = 'Erreur : $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(int id, int userId) async {
    try {
      // 1️⃣ SQLite d'abord
      await _db.deleteBudget(id);
      // 2️⃣ Sync API en arrière-plan
      _api.deleteBudget(id).catchError((_) {});
      await loadBudgets(userId);
      return true;
    } catch (e) {
      _error = 'Erreur : $e';
      notifyListeners();
      return false;
    }
  }

  // ─── ALERTES BUDGET ──────────────────────────────────────

  /// Vérifie les budgets et envoie les notifications si nécessaire
  Future<void> _checkBudgetAlerts(int userId) async {
    final notifCtrl = NotificationController();
    for (final budget in _budgets) {
      if (budget.id == null) continue;
      final id = budget.id!;

      if (budget.isOverBudget) {
        if (!_notifiedExceeded.contains(id)) {
          final alreadyDbNotified = await _db.hasBudgetNotificationForMonth(
            userId: userId,
            categoryName: budget.categoryName,
            month: budget.month,
            year: budget.year,
            type: 'exceeded',
          );

          if (!alreadyDbNotified) {
            _notifiedExceeded.add(id);
            final title = '⚠️ Budget dépassé — ${budget.categoryName}';
            final message = 'Tu as dépensé ${budget.spentAmount.toStringAsFixed(0)} MAD sur un budget de ${budget.limitAmount.toStringAsFixed(0)} MAD.';
            
            _notif.sendBudgetExceededNotif(
              categoryName: budget.categoryName,
              spent: budget.spentAmount,
              limit: budget.limitAmount,
              currency: 'MAD',
            ).catchError((_) {});

            await notifCtrl.addNotification(
              userId: userId,
              title: title,
              message: message,
            );
          } else {
            _notifiedExceeded.add(id);
          }
        }
      } else {
        _notifiedExceeded.remove(id);
      }

      if (!budget.isOverBudget && budget.usagePercent >= 0.8) {
        if (!_notifiedWarning.contains(id)) {
          final alreadyDbNotified = await _db.hasBudgetNotificationForMonth(
            userId: userId,
            categoryName: budget.categoryName,
            month: budget.month,
            year: budget.year,
            type: 'warning',
          );

          if (!alreadyDbNotified) {
            _notifiedWarning.add(id);
            final percent = (budget.usagePercent * 100).toInt();
            final title = '🔔 Budget presque atteint — ${budget.categoryName}';
            final message = 'Tu as utilisé $percent% de ton budget pour cette catégorie.';

            _notif.sendBudgetWarningNotif(
              categoryName: budget.categoryName,
              percent: percent,
              currency: 'MAD',
            ).catchError((_) {});

            await notifCtrl.addNotification(
              userId: userId,
              title: title,
              message: message,
            );
          } else {
            _notifiedWarning.add(id);
          }
        }
      } else if (budget.usagePercent < 0.8) {
        _notifiedWarning.remove(id);
      }
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
