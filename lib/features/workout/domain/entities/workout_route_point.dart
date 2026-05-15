class WorkoutRoutePoint {
  const WorkoutRoutePoint({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;

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
    };
  }

  factory WorkoutRoutePoint.fromJson(Map<String, Object?> json) {
    return WorkoutRoutePoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}
