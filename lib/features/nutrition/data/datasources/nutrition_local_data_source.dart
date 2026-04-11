import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/food_entry_model.dart';

abstract interface class NutritionLocalDataSource {
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  });

  Future<List<FoodEntryModel>> loadPendingFoodEntries({required String userId});

  Future<void> saveFoodEntry(FoodEntryModel entry);

  Future<void> saveFoodEntries(List<FoodEntryModel> entries);

  Future<void> markFoodEntrySynced(String entryId);
}

class SqfliteNutritionLocalDataSource implements NutritionLocalDataSource {
  SqfliteNutritionLocalDataSource();

  static const String _databaseName = 'liga_gym_nutrition.db';
  static const String _tableName = 'food_entries';

  Database? _database;

  Future<Database> get _db async {
    final database = _database;
    if (database != null) {
      return database;
    }

    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            date_key TEXT NOT NULL,
            product_name_en TEXT NOT NULL,
            product_name_ru TEXT NOT NULL,
            barcode TEXT,
            grams REAL NOT NULL,
            calories REAL NOT NULL,
            proteins REAL NOT NULL,
            fats REAL NOT NULL,
            carbs REAL NOT NULL,
            logged_at INTEGER NOT NULL,
            input_method TEXT NOT NULL,
            is_synced INTEGER NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  @override
  Future<List<FoodEntryModel>> loadDailyFoodEntries({
    required String userId,
    required DateTime date,
  }) async {
    final database = await _db;
    final maps = await database.query(
      _tableName,
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, buildDateKey(date)],
      orderBy: 'logged_at ASC',
    );

    return maps.map(FoodEntryModel.fromLocalMap).toList(growable: false);
  }

  @override
  Future<List<FoodEntryModel>> loadPendingFoodEntries({
    required String userId,
  }) async {
    final database = await _db;
    final maps = await database.query(
      _tableName,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
      orderBy: 'logged_at ASC',
    );

    return maps.map(FoodEntryModel.fromLocalMap).toList(growable: false);
  }

  @override
  Future<void> saveFoodEntry(FoodEntryModel entry) async {
    final database = await _db;
    await database.insert(
      _tableName,
      entry.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveFoodEntries(List<FoodEntryModel> entries) async {
    if (entries.isEmpty) {
      return;
    }

    final database = await _db;
    final batch = database.batch();

    for (final entry in entries) {
      batch.insert(
        _tableName,
        entry.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> markFoodEntrySynced(String entryId) async {
    final database = await _db;
    await database.update(
      _tableName,
      <String, Object?>{'is_synced': 1},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }
}
