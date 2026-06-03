// Modèle représentant une notification in-app (budget dépassé, avertissements, etc.)

class NotificationModel {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  /// Convertit un modèle en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  /// Crée un modèle à partir d'un Map SQLite
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isRead: (map['isRead'] as int) == 1,
    );
  }

  /// Retourne une copie du modèle avec des champs modifiés
  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
