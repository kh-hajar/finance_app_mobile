// lib/views/stats/stats_view.dart
// Écran statistiques avec graphiques (camembert + barres)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_theme.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  List<Map<String, dynamic>> _categoryData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  bool _loading = true;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharge les stats si le filtre de mois change depuis une autre page
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthController>();
    final txCtrl = context.read<TransactionController>();
    if (auth.currentUser == null) return;

    if (!mounted) return;
    setState(() => _loading = true);

    final userId = auth.currentUser!.id!;
    final cats = await txCtrl.getExpensesByCategory(userId);
    final monthly = await txCtrl.getMonthlyStats(userId);

    if (!mounted) return;
    setState(() {
      _categoryData = cats;
      _monthlyData = monthly;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final txCtrl = context.watch<TransactionController>();
    final theme = context.watch<ThemeController>();
    final isDark = theme.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre section camembert
                    Text(
                      'Dépenses par catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      AppHelpers.formatMonthYear(
                          txCtrl.filterMonth, txCtrl.filterYear),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Camembert
                    if (_categoryData.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'Aucune dépense ce mois',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      response == null ||
                                      response.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = response
                                      .touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sections: _buildPieSections(),
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Légende
                      ..._categoryData.asMap().entries.map((e) {
                        final item = e.value;
                        final color = AppHelpers.colorFromHex(
                            item['categoryColor'] as String);
                        final total =
                            (item['total'] as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['categoryName'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppTheme.textPrimaryDark
                                        : AppTheme.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Text(
                                AppHelpers.formatAmount(total, theme.currency),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Graphique barres mensuelles
                    Text(
                      'Évolution sur 6 mois',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_monthlyData.isEmpty)
                      Center(
                        child: Text(
                          'Pas encore de données',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: _buildBarChart(isDark),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = _categoryData.fold<double>(
        0, (sum, item) => sum + (item['total'] as num).toDouble());

    return _categoryData.asMap().entries.map((e) {
      final i = e.key;
      final item = e.value;
      final value = (item['total'] as num).toDouble();
      final percent = total > 0 ? (value / total * 100) : 0.0;
      final color = AppHelpers.colorFromHex(item['categoryColor'] as String);
      final isTouched = i == _touchedIndex;

      return PieChartSectionData(
        value: value,
        color: color,
        radius: isTouched ? 72 : 60,
        title: '${percent.toStringAsFixed(0)}%',
        titleStyle: TextStyle(
          fontSize: isTouched ? 13 : 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildBarChart(bool isDark) {
    // Construire les données des 6 derniers mois
    final months = <String>{};
    for (final item in _monthlyData) {
      months.add(item['month'] as String);
    }
    final sortedMonths = months.toList()..sort();

    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};
    for (final item in _monthlyData) {
      final m = item['month'] as String;
      final t = (item['total'] as num).toDouble();
      if (item['type'] == 'income') {
        incomeMap[m] = t;
      } else {
        expenseMap[m] = t;
      }
    }

    final barGroups = sortedMonths.asMap().entries.map((e) {
      final i = e.key;
      final m = e.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: incomeMap[m] ?? 0,
            color: AppTheme.incomeColor,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: expenseMap[m] ?? 0,
            color: AppTheme.expenseColor,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 3,
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.15),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) => Text(
                '${(v / 1000).toStringAsFixed(0)}k',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i >= sortedMonths.length) return const SizedBox();
                final parts = sortedMonths[i].split('-');
                final month = int.parse(parts[1]);
                return Text(
                  AppHelpers.monthNames[month - 1].substring(0, 3),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}