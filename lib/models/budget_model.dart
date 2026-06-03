// Modèle représentant un budget mensuel par catégorie

class BudgetModel {
  final int? id;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;
  final double limitAmount;   // plafond du budget
  final double spentAmount;   // montant déjà dépensé (calculé)
  final int month;            // 1-12
  final int year;
  final int userId;

  BudgetModel({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.limitAmount,
    this.spentAmount = 0,
    required this.month,
    required this.year,
    required this.userId,
  });

  /// Pourcentage utilisé du budget (0.0 à 1.0+)
  double get usagePercent =>
      limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.5) : 0.0;

  /// Indique si le budget est dépassé
  bool get isOverBudget => spentAmount > limitAmount;

  /// Montant restant (peut être négatif si dépassé)
  double get remaining => limitAmount - spentAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryColor': categoryColor,
      'categoryIcon': categoryIcon,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
      'userId': userId,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['categoryId'] as int,
      categoryName: map['categoryName'] as String,
      categoryColor: map['categoryColor'] as String,
      categoryIcon: map['categoryIcon'] as String,
      limitAmount: (map['limitAmount'] as num).toDouble(),
      spentAmount: (map['spentAmount'] as num? ?? 0).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
      userId: map['userId'] as int,
    );
  }

  BudgetModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    double? limitAmount,
    double? spentAmount,
    int? month,
    int? year,
    int? userId,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      userId: userId ?? this.userId,
    );
  }
}