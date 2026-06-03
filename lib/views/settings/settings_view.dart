// Écran paramètres : dark mode, devise, déconnexion

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil utilisateur
          _sectionHeader('Profil', isDark),
          _card(
            isDark,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Apparence
          _sectionHeader('Apparence', isDark),
          _card(
            isDark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _iconBox(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        AppTheme.primaryGreen,
                        isDark),
                    const SizedBox(width: 12),
                    Text(
                      'Mode sombre',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => theme.toggleDarkMode(),
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Devise
          _sectionHeader('Devise', isDark),
          _card(
            isDark,
            child: Column(
              children: AppHelpers.currencies.map((c) {
                final isSelected = theme.currency == c;
                return GestureDetector(
                  onTap: () => theme.setCurrency(c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : (isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.primaryGreen, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // À propos
          _sectionHeader('Application', isDark),
          _card(
            isDark,
            child: Column(
              children: [
                _settingRow(
                    Icons.info_outline_rounded,
                    'Version',
                    AppConstants.appVersion,
                    isDark),
                const Divider(height: 1),
                _settingRow(
                    Icons.storage_rounded,
                    'Architecture',
                    'MVC + SQLite',
                    isDark),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Déconnexion
          _card(
            isDark,
            child: GestureDetector(
              onTap: () => _confirmLogout(context, auth),
              child: Row(
                children: [
                  _iconBox(Icons.logout_rounded, AppTheme.expenseColor, isDark),
                  const SizedBox(width: 12),
                  const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        ),
      ),
    );
  }

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _settingRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _iconBox(icon, AppTheme.primaryGreen, isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
      BuildContext context, AuthController auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: AppTheme.expenseColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
      }
    }
  }
}