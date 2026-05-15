import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/workout_model.dart';

abstract interface class WorkoutLocalDataSource {
  Future<List<WorkoutModel>> loadUserWorkouts(String userId);

  Future<List<WorkoutModel>> loadPendingWorkouts(String userId);

  Future<void> saveWorkout(WorkoutModel workout);

  Future<void> saveWorkouts(List<WorkoutModel> workouts);

  Future<void> markWorkoutSynced(String workoutId);
}

class SqfliteWorkoutLocalDataSource implements WorkoutLocalDataSource {
  SqfliteWorkoutLocalDataSource();

  static const String _databaseName = 'liga_gym_workouts.db';
  static const String _tableName = 'workouts';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            type TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            calories REAL NOT NULL,
            distance_meters REAL NOT NULL,
            route_json TEXT NOT NULL,
            is_synced INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureRouteColumn(db);
      },
      onOpen: (db) async {
        await _ensureRouteColumn(db);
      },
    );

    return _database!;
  }

  @override
  Future<List<WorkoutModel>> loadUserWorkouts(String userId) async {
    final database = await _db;
    final maps = await database.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'started_at DESC',
    );

    return maps.map(WorkoutModel.fromLocalMap).toList(growable: false);
  }

  @override
  Future<List<WorkoutModel>> loadPendingWorkouts(String userId) async {
    final database = await _db;
    final maps = await database.query(
      _tableName,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
      orderBy: 'started_at ASC',
    );

    return maps.map(WorkoutModel.fromLocalMap).toList(growable: false);
  }

  @override
  Future<void> saveWorkout(WorkoutModel workout) async {
    final database = await _db;
    await database.insert(
      _tableName,
      workout.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveWorkouts(List<WorkoutModel> workouts) async {
    if (workouts.isEmpty) {
      return;
    }

    final database = await _db;
    final batch = database.batch();

    for (final workout in workouts) {
      batch.insert(
        _tableName,
        workout.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> markWorkoutSynced(String workoutId) async {
    final database = await _db;
    await database.update(
      _tableName,
      <String, Object?>{'is_synced': 1},
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<void> _ensureRouteColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info($_tableName)');
    final hasRouteColumn = columns.any(
      (column) => column['name'] == 'route_json',
    );
    if (hasRouteColumn) {
      return;
    }

    await db.execute(
      "ALTER TABLE $_tableName ADD COLUMN route_json TEXT NOT NULL DEFAULT '[]'",
    );
  }
}
