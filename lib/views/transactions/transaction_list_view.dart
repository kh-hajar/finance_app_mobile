// Liste complète des transactions avec filtres

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../widgets/transaction_card.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final txCtrl = context.watch<TransactionController>();
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;
    final userId = auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          // Sélecteur de mois
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showMonthPicker(context, txCtrl, userId!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      AppHelpers.monthNames[txCtrl.filterMonth - 1]
                          .substring(0, 3),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primaryGreen, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre type
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _filterChip(context, 'all', 'Tous', txCtrl, isDark),
                const SizedBox(width: 8),
                _filterChip(context, 'income', 'Revenus', txCtrl, isDark),
                const SizedBox(width: 8),
                _filterChip(context, 'expense', 'Dépenses', txCtrl, isDark),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Liste
          Expanded(
            child: txCtrl.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen))
                : txCtrl.filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune transaction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ajoutez votre première transaction',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: txCtrl.filteredTransactions.length,
                        itemBuilder: (ctx, i) {
                          final t = txCtrl.filteredTransactions[i];
                          return TransactionCard(
                            transaction: t,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppConstants.routeEditTransaction,
                              arguments: t,
                            ),
                            onDelete: () async {
                              await txCtrl.deleteTransaction(t.id!, userId!);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppConstants.routeAddTransaction),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _filterChip(BuildContext context, String type, String label,
      TransactionController ctrl, bool isDark) {
    final isSelected = ctrl.filterType == type;
    Color color;
    switch (type) {
      case 'income':
        color = AppTheme.incomeColor;
        break;
      case 'expense':
        color = AppTheme.expenseColor;
        break;
      default:
        color = AppTheme.primaryGreen;
    }
    return GestureDetector(
      onTap: () => ctrl.setFilter(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark
                  ? AppTheme.cardDark
                  : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? color
                : (isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, TransactionController ctrl,
      int userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final now = DateTime.now();
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sélectionner un mois',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final month = i + 1;
                  final isSelected = ctrl.filterMonth == month &&
                      ctrl.filterYear == now.year;
                  return GestureDetector(
                    onTap: () {
                      ctrl.setMonthFilter(userId, month, now.year);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        AppHelpers.monthNames[i].substring(0, 3),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}