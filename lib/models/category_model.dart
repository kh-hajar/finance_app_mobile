// Modèle représentant une catégorie de transaction

class CategoryModel {
  final int? id;
  final String name;
  final String icon;     // nom d'icône (ex: 'food', 'car', 'home')
  final String color;    // hex color 
  final String type;     // 'income' ou 'expense'
  final int userId;

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'userId': userId,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: map['type'] as String,
      userId: map['userId'] as int,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    String? icon,
    String? color,
    String? type,
    int? userId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, type: $type)';

  /// Catégories par défaut pour un nouvel utilisateur
  static List<CategoryModel> defaultCategories(int userId) {
    return [
      // Dépenses
      CategoryModel(name: 'Alimentation', icon: 'food', color: '#FF6B6B', type: 'expense', userId: userId),
      CategoryModel(name: 'Transport', icon: 'car', color: '#4ECDC4', type: 'expense', userId: userId),
      CategoryModel(name: 'Logement', icon: 'home', color: '#45B7D1', type: 'expense', userId: userId),
      CategoryModel(name: 'Santé', icon: 'health', color: '#96CEB4', type: 'expense', userId: userId),
      CategoryModel(name: 'Loisirs', icon: 'fun', color: '#FFEAA7', type: 'expense', userId: userId),
      CategoryModel(name: 'Vêtements', icon: 'clothes', color: '#DDA0DD', type: 'expense', userId: userId),
      CategoryModel(name: 'Éducation', icon: 'education', color: '#98D8C8', type: 'expense', userId: userId),
      CategoryModel(name: 'Autres dépenses', icon: 'other', color: '#B0B0B0', type: 'expense', userId: userId),
      // Revenus
      CategoryModel(name: 'Salaire', icon: 'salary', color: '#2ECC71', type: 'income', userId: userId),
      CategoryModel(name: 'Freelance', icon: 'work', color: '#3498DB', type: 'income', userId: userId),
      CategoryModel(name: 'Investissements', icon: 'invest', color: '#F39C12', type: 'income', userId: userId),
      CategoryModel(name: 'Autres revenus', icon: 'other', color: '#1ABC9C', type: 'income', userId: userId),
    ];
  }
}