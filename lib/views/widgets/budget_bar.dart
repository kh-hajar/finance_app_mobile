// Widget barre de progression pour les budgets

import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class BudgetBar extends StatelessWidget {
  final BudgetModel budget;
  final String currency;

  const BudgetBar({
    super.key,
    required this.budget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppHelpers.colorFromHex(budget.categoryColor);
    final percent = budget.usagePercent.clamp(0.0, 1.0);
    final isOver = budget.isOverBudget;
    final barColor = isOver ? AppTheme.expenseColor : color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOver
              ? AppTheme.expenseColor.withOpacity(0.3)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppHelpers.getCategoryIcon(budget.categoryIcon),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budget.categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        if (isOver)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Dépassé',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.expenseColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppHelpers.formatAmount(budget.spentAmount, currency)} / ${AppHelpers.formatAmount(budget.limitAmount, currency)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}