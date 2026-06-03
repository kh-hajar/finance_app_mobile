import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class NotificationController extends ChangeNotifier {
  // Singleton pattern
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  final DatabaseService _db = DatabaseService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Charge toutes les notifications pour un utilisateur
  Future<void> loadNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notifications = await _db.getNotificationsByUser(userId);
    } catch (e) {
      debugPrint('Erreur lors du chargement des notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute une notification dans la base de données et met à jour l'état
  Future<void> addNotification({
    required int userId,
    required String title,
    required String message,
  }) async {
    final notification = NotificationModel(
      userId: userId,
      title: title,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
    );

    try {
      await _db.insertNotification(notification);
      // Recharger pour mettre à jour la liste locale et notifier les écouteurs
      await loadNotifications(userId);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la notification: $e');
    }
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(int notificationId, int userId) async {
    try {
      await _db.markNotificationAsRead(notificationId);
      // Mettre à jour localement pour réactivité immédiate sans rechargement complet
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage comme lu: $e');
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> markAllAsRead(int userId) async {
    try {
      await _db.markAllNotificationsAsRead(userId);
      // Mettre à jour localement
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du marquage de toutes comme lues: $e');
    }
  }

  /// Supprime une notification
  Future<void> deleteNotification(int notificationId, int userId) async {
    try {
      await _db.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la notification: $e');
    }
  }

  /// Supprime toutes les notifications
  Future<void> clearAll(int userId) async {
    try {
      await _db.clearAllNotifications(userId);
      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la suppression de toutes les notifications: $e');
    }
  }
}
