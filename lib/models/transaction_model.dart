// Modèle représentant une transaction financière (revenu ou dépense)

class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type;          // 'income' ou 'expense'
  final int categoryId;
  final String categoryName;  // dénormalisé pour affichage rapide
  final String categoryColor;
  final String categoryIcon;
  final DateTime date;
  final String? note;
  final int userId;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.date,
    this.note,
    required this.userId,
  });

  /// Indique si c'est un revenu
  bool get isIncome => type == 'income';

  /// Indique si c'est une dépense
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryColor': categoryColor,
      'categoryIcon': categoryIcon,
      'date': date.toIso8601String(),
      'note': note,
      'userId': userId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['categoryId'] as int,
      categoryName: map['categoryName'] as String,
      categoryColor: map['categoryColor'] as String,
      categoryIcon: map['categoryIcon'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      userId: map['userId'] as int,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    DateTime? date,
    String? note,
    int? userId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, title: $title, amount: $amount, type: $type)';
}