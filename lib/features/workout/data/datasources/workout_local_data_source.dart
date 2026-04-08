import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/workout_model.dart';

abstract interface class WorkoutLocalDataSource {
  Future<List<WorkoutModel>> loadUserWorkouts(String userId);

  Future<void> saveWorkout(WorkoutModel workout);

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
      version: 1,
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
  Future<void> saveWorkout(WorkoutModel workout) async {
    final database = await _db;
    await database.insert(
      _tableName,
      workout.toLocalMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
}
