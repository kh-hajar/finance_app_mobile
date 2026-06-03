// Service de notifications locales
// Utilisé pour alerter l'utilisateur quand un budget est dépassé

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // ─── SINGLETON ───────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── INITIALISATION ──────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  // ─── DÉTAILS DU CANAL ANDROID ────────────────────────────

  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'budget_channel',       // channel id
        'Alertes Budget',       // channel name
        channelDescription: 'Notifications de dépassement de budget',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

  NotificationDetails get _notifDetails => NotificationDetails(
        android: _androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

  // ─── NOTIFICATION BUDGET DÉPASSÉ ────────────────────────

  /// Envoie une notification quand un budget de catégorie est dépassé
  Future<void> sendBudgetExceededNotif({
    required String categoryName,
    required double spent,
    required double limit,
    required String currency,
  }) async {
    await init();
    final id = categoryName.hashCode.abs() % 10000;

    await _plugin.show(
      id,
      '⚠️ Budget dépassé — $categoryName',
      'Tu as dépensé ${spent.toStringAsFixed(0)} $currency '
          'sur un budget de ${limit.toStringAsFixed(0)} $currency.',
      _notifDetails,
    );
  }

  // ─── NOTIFICATION BUDGET PROCHE ─────────────────────────

  /// Envoie une notification quand un budget dépasse 80%
  Future<void> sendBudgetWarningNotif({
    required String categoryName,
    required int percent,
    required String currency,
  }) async {
    await init();
    final id = ('warn_$categoryName').hashCode.abs() % 10000;

    await _plugin.show(
      id,
      '🔔 Budget presque atteint — $categoryName',
      'Tu as utilisé $percent% de ton budget pour cette catégorie.',
      _notifDetails,
    );
  }

  // ─── ANNULER TOUTES LES NOTIFICATIONS ───────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
