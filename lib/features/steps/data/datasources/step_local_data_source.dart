import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/daily_step_count_model.dart';

abstract interface class StepLocalDataSource {
  Future<List<DailyStepCountModel>> loadStepCounts({
    required String userId,
    required DateTime from,
    required DateTime to,
  });

  Future<int> loadStepsForDate({
    required String userId,
    required DateTime date,
  });

  Future<void> recordSensorReading({
    required String userId,
    required int sensorSteps,
    required DateTime recordedAt,
  });
}

class SqfliteStepLocalDataSource implements StepLocalDataSource {
  SqfliteStepLocalDataSource();

  static const String _databaseName = 'liga_gym_steps.db';
  static const String _dailyStepsTable = 'daily_steps';
  static const String _sensorStateTable = 'step_sensor_state';

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
          CREATE TABLE $_dailyStepsTable(
            user_id TEXT NOT NULL,
            date_key TEXT NOT NULL,
            steps INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (user_id, date_key)
          )
        ''');
        await db.execute('''
          CREATE TABLE $_sensorStateTable(
            user_id TEXT PRIMARY KEY,
            last_sensor_steps INTEGER NOT NULL,
            last_sensor_timestamp INTEGER NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  @override
  Future<List<DailyStepCountModel>> loadStepCounts({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final database = await _db;
    final maps = await database.query(
      _dailyStepsTable,
      where: 'user_id = ? AND date_key >= ? AND date_key <= ?',
      whereArgs: [userId, buildStepDateKey(from), buildStepDateKey(to)],
      orderBy: 'date_key ASC',
    );

    return maps.map(DailyStepCountModel.fromLocalMap).toList(growable: false);
  }

  @override
  Future<int> loadStepsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final database = await _db;
    final maps = await database.query(
      _dailyStepsTable,
      columns: ['steps'],
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, buildStepDateKey(date)],
      limit: 1,
    );

    if (maps.isEmpty) {
      return 0;
    }

    return maps.first['steps']! as int;
  }

  @override
  Future<void> recordSensorReading({
    required String userId,
    required int sensorSteps,
    required DateTime recordedAt,
  }) async {
    final database = await _db;
    final dateKey = buildStepDateKey(recordedAt);
    final updatedAt = recordedAt.millisecondsSinceEpoch;

    await database.transaction((txn) async {
      final stateMaps = await txn.query(
        _sensorStateTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (stateMaps.isEmpty) {
        await txn.insert(_sensorStateTable, <String, Object?>{
          'user_id': userId,
          'last_sensor_steps': sensorSteps,
          'last_sensor_timestamp': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      }

      final state = stateMaps.first;
      final previousSensorSteps = state['last_sensor_steps']! as int;
      final previousTimestamp = state['last_sensor_timestamp']! as int;

      if (sensorSteps < previousSensorSteps || updatedAt < previousTimestamp) {
        await txn.insert(_sensorStateTable, <String, Object?>{
          'user_id': userId,
          'last_sensor_steps': sensorSteps,
          'last_sensor_timestamp': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      }

      final delta = sensorSteps - previousSensorSteps;
      if (delta > 0) {
        final currentDayMaps = await txn.query(
          _dailyStepsTable,
          where: 'user_id = ? AND date_key = ?',
          whereArgs: [userId, dateKey],
          limit: 1,
        );

        final currentSteps = currentDayMaps.isEmpty
            ? 0
            : currentDayMaps.first['steps']! as int;

        await txn.insert(_dailyStepsTable, <String, Object?>{
          'user_id': userId,
          'date_key': dateKey,
          'steps': currentSteps + delta,
          'updated_at': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.insert(_sensorStateTable, <String, Object?>{
        'user_id': userId,
        'last_sensor_steps': sensorSteps,
        'last_sensor_timestamp': updatedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }
}
