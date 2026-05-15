import 'package:geolocator/geolocator.dart';

import '../../domain/entities/workout_route_point.dart';

abstract interface class WorkoutLocationDataSource {
  Future<bool> prepareTracking();

  Future<void> openLocationSettings();

  Stream<WorkoutRoutePoint> watchRoute();
}

class GeolocatorWorkoutLocationDataSource implements WorkoutLocationDataSource {
  const GeolocatorWorkoutLocationDataSource();

  @override
  Future<bool> prepareTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<void> openLocationSettings() async {
    final serviceOpened = await Geolocator.openLocationSettings();
    if (!serviceOpened) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Stream<WorkoutRoutePoint> watchRoute() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    return Geolocator.getPositionStream(locationSettings: settings)
        .map(
          (position) => WorkoutRoutePoint(
            latitude: position.latitude,
            longitude: position.longitude,
            recordedAt: position.timestamp,
          ),
        )
        .where((point) => point.hasValidCoordinates);
  }
}
