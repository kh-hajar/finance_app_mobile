// Service singleton gérant toutes les opérations SQLite

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static Future<Database>? _initFuture; // Garde la Future d'init pour éviter les appels concurrents

  static const String _dbName = 'finance_app.db';
  static const int _dbVersion = 1;

  // Noms des tables
  static const String tableUsers = 'users';
  static const String tableTransactions = 'transactions';
  static const String tableCategories = 'categories';
  static const String tableBudgets = 'budgets';

  /// Retourne l'instance de la base de données (thread-safe)
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Si une initialisation est déjà en cours, on attend la même Future
    _initFuture ??= _initDatabase();
    _database = await _initFuture;
    return _database!;
  }

  /// Initialise la base de données SQLite
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables au premier lancement
  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        avatarPath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Table catégories
    await db.execute('''
      CREATE TABLE $tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id)
      )
    ''');

    // Table transactions
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        categoryName TEXT NOT NULL,
        categoryColor TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id),
        FOREIGN KEY (categoryId) REFERENCES $tableCategories(id)
      )
    ''');

    // Table budgets
    await db.execute('''
      CREATE TABLE $tableBudgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        categoryName TEXT NOT NULL,
        categoryColor TEXT NOT NULL,
        categoryIcon TEXT NOT NULL,
        limitAmount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUsers(id),
        FOREIGN KEY (categoryId) REFERENCES $tableCategories(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures
  }

  // ─── USERS ───────────────────────────────────────────────

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert(tableUsers, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps =
        await db.query(tableUsers, where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final maps =
        await db.query(tableUsers, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(tableUsers, user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  // ─── CATEGORIES ──────────────────────────────────────────

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert(tableCategories, category.toMap());
  }

  Future<List<CategoryModel>> getCategoriesByUser(int userId) async {
    final db = await database;
    final maps = await db
        .query(tableCategories, where: 'userId = ?', whereArgs: [userId]);
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(
      int userId, String type) async {
    final db = await database;
    final maps = await db.query(tableCategories,
        where: 'userId = ? AND type = ?', whereArgs: [userId, type]);
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    return await db.update(tableCategories, category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db
        .delete(tableCategories, where: 'id = ?', whereArgs: [id]);
  }

  // ─── TRANSACTIONS ─────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert(tableTransactions, transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactionsByUser(int userId,
      {int? limit, String? type, int? month, int? year}) async {
    final db = await database;
    String where = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }
    if (month != null && year != null) {
      final monthStr = month.toString().padLeft(2, '0');
      where += ' AND date LIKE ?';
      whereArgs.add('$year-$monthStr%');
    }

    final maps = await db.query(
      tableTransactions,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<TransactionModel?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db
        .query(tableTransactions, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TransactionModel.fromMap(maps.first);
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(tableTransactions, transaction.toMap(),
        where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db
        .delete(tableTransactions, where: 'id = ?', whereArgs: [id]);
  }

  /// Somme des transactions par type et mois
  Future<double> getSumByType(
      int userId, String type, int month, int year) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) as total
      FROM $tableTransactions
      WHERE userId = ? AND type = ? AND date LIKE ?
    ''', [userId, type, '$year-$monthStr%']);
    return (result.first['total'] as num? ?? 0).toDouble();
  }

  /// Dépenses groupées par catégorie pour le mois
  Future<List<Map<String, dynamic>>> getExpensesByCategory(
      int userId, int month, int year) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    return await db.rawQuery('''
      SELECT categoryId, categoryName, categoryColor, categoryIcon,
             SUM(amount) as total
      FROM $tableTransactions
      WHERE userId = ? AND type = 'expense' AND date LIKE ?
      GROUP BY categoryId
      ORDER BY total DESC
    ''', [userId, '$year-$monthStr%']);
  }

  /// Données pour le graphique des N derniers mois
  Future<List<Map<String, dynamic>>> getMonthlyStats(
      int userId, int months) async {
    final db = await database;
    // Calcul de la date de coupure en Dart pour éviter les problèmes
    // de comparaison TEXT avec date('now') de SQLite
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - months + 1, 1);
    final cutoffStr =
        '${cutoff.year}-${cutoff.month.toString().padLeft(2, '0')}-01';
    return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', date) as month,
        type,
        SUM(amount) as total
      FROM $tableTransactions
      WHERE userId = ?
        AND date >= ?
      GROUP BY strftime('%Y-%m', date), type
      ORDER BY month ASC
    ''', [userId, cutoffStr]);
  }

  // ─── BUDGETS ─────────────────────────────────────────────

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert(tableBudgets, budget.toMap());
  }

  Future<List<BudgetModel>> getBudgetsByMonth(
      int userId, int month, int year) async {
    final db = await database;
    final maps = await db.query(tableBudgets,
        where: 'userId = ? AND month = ? AND year = ?',
        whereArgs: [userId, month, year]);
    return maps.map((m) => BudgetModel.fromMap(m)).toList();
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await database;
    return await db.update(tableBudgets, budget.toMap(),
        where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db
        .delete(tableBudgets, where: 'id = ?', whereArgs: [id]);
  }

  /// Ferme la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
