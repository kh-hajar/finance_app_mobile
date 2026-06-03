import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../models/notification_model.dart';
import '../../../utils/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthController>(context, listen: false);
      if (auth.currentUser != null) {
        Provider.of<NotificationController>(context, listen: false)
            .loadNotifications(auth.currentUser!.id!);
      }
    });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return "Il y a ${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "Il y a ${difference.inHours} h";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else {
      return DateFormat('dd MMM à HH:mm', 'fr_FR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;
    final auth = context.watch<AuthController>();
    final notifCtrl = context.watch<NotificationController>();
    final userId = auth.currentUser?.id ?? 0;
    
    final notifications = notifCtrl.notifications;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F6FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Barre de glissement supérieure (handle)
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // En-tête
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    letterSpacing: -0.5,
                  ),
                ),
                if (notifications.isNotEmpty)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => notifCtrl.markAllAsRead(userId),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Tout lire',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => notifCtrl.clearAll(userId),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.expenseColor,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Tout effacer',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),

          // Contenu principal
          Expanded(
            child: notifCtrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                  )
                : notifications.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationItem(context, notif, userId, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 54,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez alerté ici en cas de dépassement de budget ou d\'approches de vos limites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notif,
    int userId,
    bool isDark,
  ) {
    final isCritical = notif.title.contains('⚠️') || notif.title.toLowerCase().contains('dépassé');
    final iconColor = isCritical ? AppTheme.expenseColor : const Color(0xFFFFB300);
    final itemBg = notif.isRead
        ? Colors.transparent
        : (isDark ? Colors.white.withOpacity(0.03) : AppTheme.primaryGreen.withOpacity(0.04));

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.expenseColor,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        Provider.of<NotificationController>(context, listen: false)
            .deleteNotification(notif.id!, userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification supprimée'),
            action: SnackBarAction(
              label: 'Annuler',
              textColor: AppTheme.primaryGreen,
              onPressed: () {
                // Optionnel : rajouter en DB si besoin d'annuler
                Provider.of<NotificationController>(context, listen: false)
                    .addNotification(
                  userId: userId,
                  title: notif.title,
                  message: notif.message,
                );
              },
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notif.isRead) {
            Provider.of<NotificationController>(context, listen: false)
                .markAsRead(notif.id!, userId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: itemBg,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.08),
                width: 1,
              ),
              left: BorderSide(
                color: notif.isRead ? Colors.transparent : iconColor,
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),

              // Contenu textuel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(notif.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
