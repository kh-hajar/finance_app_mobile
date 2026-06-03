// Constantes et helpers globaux de l'application

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Financia';
  static const String appVersion = '1.0.0';

  // ─── ROUTES ───────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeAddTransaction = '/add-transaction';
  static const String routeEditTransaction = '/edit-transaction';
}

class AppHelpers {
  // ─── LISTES ───────────────────────────────────────────────

  static const List<String> monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  static const List<String> currencies = [
    'MAD', 'EUR', 'USD', 'GBP', 'CAD', 'CHF',
  ];

  // ─── COULEURS ─────────────────────────────────────────────

  /// Convertit un code couleur hex (#RRGGBB) en Color Flutter
  static Color colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  // ─── ICÔNES ───────────────────────────────────────────────

  /// Retourne une IconData à partir d'un nom d'icône de catégorie
  static IconData getCategoryIcon(String icon) {
    switch (icon) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'fun':
        return Icons.sports_esports_rounded;
      case 'clothes':
        return Icons.checkroom_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'salary':
        return Icons.work_rounded;
      case 'work':
        return Icons.computer_rounded;
      case 'invest':
        return Icons.trending_up_rounded;
      case 'other':
        return Icons.category_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  // ─── FORMATAGE ────────────────────────────────────────────

  /// Format : "14 juin 2025"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  /// Format : "14/06/2025"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format : "1 250,00 MAD"
  static String formatAmount(double amount, String currency) {
    final formatted = NumberFormat('#,##0.00', 'fr_FR').format(amount);
    return '$formatted $currency';
  }

  /// Format : "Juin 2025"
  static String formatMonthYear(int month, int year) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy', 'fr_FR').format(date);
  }
}
