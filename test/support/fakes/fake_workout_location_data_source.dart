import 'dart:async';

import 'package:liga_gym_app/features/workout/data/datasources/workout_location_data_source.dart';
import 'package:liga_gym_app/features/workout/domain/entities/workout_route_point.dart';

class FakeWorkoutLocationDataSource implements WorkoutLocationDataSource {
  FakeWorkoutLocationDataSource({this.isTrackingAvailable = true});

  final bool isTrackingAvailable;
  final StreamController<WorkoutRoutePoint> _routeController =
      StreamController<WorkoutRoutePoint>.broadcast();

  @override
  Future<bool> prepareTracking() async => isTrackingAvailable;

  @override
  Stream<WorkoutRoutePoint> watchRoute() => _routeController.stream;

  void emitRoutePoint(WorkoutRoutePoint point) {
    _routeController.add(point);
  }

  Future<void> dispose() {
    return _routeController.close();
  }
}
