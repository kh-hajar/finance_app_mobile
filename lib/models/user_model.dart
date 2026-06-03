// Modèle représentant un utilisateur de l'application

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password; // stocké hashé dans la DB
  final String? avatarPath;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatarPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir un UserModel en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Créer un UserModel à partir d'une Map (lecture depuis la DB)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      avatarPath: map['avatarPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Copie avec modification
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? avatarPath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}