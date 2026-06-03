// Tableau de bord principal : solde, revenus/dépenses, transactions récentes

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/budget_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/animated_list_item.dart';
import '../../controllers/notification_controller.dart';
import 'widgets/notification_bottom_sheet.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final txCtrl = context.watch<TransactionController>();
    final theme = context.watch<ThemeController>();
    final notifCtrl = context.watch<NotificationController>();
    final isDark = theme.isDarkMode;
    final user = auth.currentUser;
    final currency = theme.currency;
    final unreadCount = notifCtrl.unreadCount;

    final recentTransactions = txCtrl.transactions.take(5).toList();
    final monthLabel = AppHelpers.formatMonthYear(
        txCtrl.filterMonth, txCtrl.filterYear);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              await Future.wait([
                txCtrl.loadData(user.id!),
                context.read<BudgetController>().loadBudgets(user.id!),
                context.read<NotificationController>().loadNotifications(user.id!),
              ]);
            }
          },
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, ${user?.name.split(' ').first ?? ''} 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      // Bouton notifications
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const NotificationBottomSheet(),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.cardDark
                                    : AppTheme.cardLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.grey.withOpacity(0.12),
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                size: 20,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.expenseColor,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cartes résumé
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Carte solde principal
                      AnimatedListItem(
                        index: 0,
                        child: SummaryCard(
                          label: 'SOLDE DISPONIBLE',
                          amount: AppHelpers.formatAmount(
                              txCtrl.balance, currency),
                          icon: Icons.account_balance_wallet_rounded,
                          color: txCtrl.balance >= 0
                              ? AppTheme.primaryGreen
                              : AppTheme.expenseColor,
                          isLarge: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Revenus + Dépenses
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedListItem(
                              index: 1,
                              child: SummaryCard(
                                label: 'Revenus',
                                amount: AppHelpers.formatAmount(
                                    txCtrl.totalIncome, currency),
                                icon: Icons.arrow_downward_rounded,
                                color: AppTheme.incomeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedListItem(
                              index: 2,
                              child: SummaryCard(
                                label: 'Dépenses',
                                amount: AppHelpers.formatAmount(
                                    txCtrl.totalExpense, currency),
                                icon: Icons.arrow_upward_rounded,
                                color: AppTheme.expenseColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Transactions récentes
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transactions récentes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      if (txCtrl.transactions.length > 5)
                        GestureDetector(
                          onTap: () {
                            // Naviguer vers l'onglet transactions
                          },
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Liste transactions récentes
              if (txCtrl.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                )
              else if (recentTransactions.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune transaction ce mois-ci',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                context, AppConstants.routeAddTransaction),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final t = recentTransactions[i];
                        return AnimatedListItem(
                          index: i + 3, // décalage après les 3 cartes
                          child: TransactionCard(
                            transaction: t,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppConstants.routeEditTransaction,
                              arguments: t,
                            ),
                            onDelete: () async {
                              await txCtrl.deleteTransaction(
                                  t.id!, user!.id!);
                            },
                          ),
                        );
                      },
                      childCount: recentTransactions.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),

      // FAB pour ajouter une transaction
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppConstants.routeAddTransaction),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}