// lib/views/budgets/budget_view.dart
// Écran de gestion des budgets mensuels

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/budget_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';
import '../widgets/budget_bar.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final budgetCtrl = context.watch<BudgetController>();
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;
    final userId = auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              AppHelpers.formatMonthYear(
                  budgetCtrl.month, budgetCtrl.year),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
      body: budgetCtrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: () async =>
                  budgetCtrl.loadBudgets(userId!),
              color: AppTheme.primaryGreen,
              child: budgetCtrl.budgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 56,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun budget défini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez des budgets pour contrôler vos dépenses',
                            textAlign: TextAlign.center,
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
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: budgetCtrl.budgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final budget = budgetCtrl.budgets[i];
                        return Dismissible(
                          key: Key('budget_${budget.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: AppTheme.expenseColor),
                          ),
                          onDismissed: (_) async {
                            await budgetCtrl.deleteBudget(
                                budget.id!, userId!);
                          },
                          child: BudgetBar(
                              budget: budget, currency: theme.currency),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetSheet(context, userId!),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context, int userId) {
    final txCtrl = context.read<TransactionController>();
    final budgetCtrl = context.read<BudgetController>();
    final theme = context.read<ThemeController>();
    final amountCtrl = TextEditingController();
    CategoryModel? selected;

    final expenseCategories = txCtrl.getCategoriesByType('expense');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau budget',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                // Catégorie
                const Text('Catégorie',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: expenseCategories.map((cat) {
                    final isSelected = selected?.id == cat.id;
                    final color =
                        AppHelpers.colorFromHex(cat.color);
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selected = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.transparent),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? color : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Montant limite
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[\d.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Plafond mensuel',
                    suffixText: theme.currency,
                    prefixIcon: const Icon(
                        Icons.attach_money_rounded,
                        size: 20),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selected == null) return;
                      final amount = double.tryParse(
                          amountCtrl.text.replaceAll(',', '.'));
                      if (amount == null || amount <= 0) return;

                      final now = DateTime.now();
                      final budget = BudgetModel(
                        categoryId: selected!.id!,
                        categoryName: selected!.name,
                        categoryColor: selected!.color,
                        categoryIcon: selected!.icon,
                        limitAmount: amount,
                        month: now.month,
                        year: now.year,
                        userId: userId,
                      );
                      await budgetCtrl.addBudget(budget);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Créer le budget'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}