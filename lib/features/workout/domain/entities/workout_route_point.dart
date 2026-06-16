class WorkoutRoutePoint {
  const WorkoutRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.altitudeMeters,
    this.accuracyMeters,
    this.speedMetersPerSecond,
    this.headingDegrees,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? altitudeMeters;
  final double? accuracyMeters;
  final double? speedMetersPerSecond;
  final double? headingDegrees;

  bool get hasValidCoordinates {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Map<String, Object?> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'recordedAt': recordedAt.toIso8601String(),
      'altitudeMeters': altitudeMeters,
      'accuracyMeters': accuracyMeters,
      'speedMetersPerSecond': speedMetersPerSecond,
      'headingDegrees': headingDegrees,
    };
  }

  factory WorkoutRoutePoint.fromJson(Map<String, Object?> json) {
    return WorkoutRoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      altitudeMeters: (json['altitudeMeters'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      speedMetersPerSecond: (json['speedMetersPerSecond'] as num?)?.toDouble(),
      headingDegrees: (json['headingDegrees'] as num?)?.toDouble(),
    );
  }
}
