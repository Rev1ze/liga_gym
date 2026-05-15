import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/workout_route_point.dart';

class WorkoutRouteMap extends StatelessWidget {
  const WorkoutRouteMap({
    super.key,
    required this.route,
    required this.emptyMessage,
    required this.fullscreenTooltip,
    this.height = 220,
    this.showWaitingState = false,
    this.waitingMessage,
    this.fullscreenTitle,
  });

  final List<WorkoutRoutePoint> route;
  final String emptyMessage;
  final String fullscreenTooltip;
  final double height;
  final bool showWaitingState;
  final String? waitingMessage;
  final String? fullscreenTitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = _buildValidLatLngs(route);

    if (points.isEmpty) {
      return _RouteMapPlaceholder(
        height: height,
        icon: showWaitingState ? Icons.gps_fixed_rounded : Icons.map_outlined,
        message: showWaitingState
            ? waitingMessage ?? emptyMessage
            : emptyMessage,
      );
    }

    final bounds = _buildSafeBounds(points);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: _WorkoutRouteMapCanvas(
                points: points,
                bounds: bounds,
                routeColor: colorScheme.primary,
                startColor: colorScheme.secondary,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: fullscreenTooltip,
                onPressed: () => _openFullscreenMap(context),
                icon: const Icon(Icons.fullscreen_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullscreenWorkoutRouteMap(
          route: route,
          title: fullscreenTitle ?? fullscreenTooltip,
        ),
      ),
    );
  }
}

List<LatLng> _buildValidLatLngs(List<WorkoutRoutePoint> route) {
  return route
      .where((point) => point.hasValidCoordinates)
      .map((point) => LatLng(point.latitude, point.longitude))
      .where((point) => point.latitude.isFinite && point.longitude.isFinite)
      .toList(growable: false);
}

LatLngBounds? _buildSafeBounds(List<LatLng> points) {
  if (points.length < 2) {
    return null;
  }

  var minLatitude = points.first.latitude;
  var maxLatitude = points.first.latitude;
  var minLongitude = points.first.longitude;
  var maxLongitude = points.first.longitude;

  for (final point in points.skip(1)) {
    minLatitude = point.latitude < minLatitude ? point.latitude : minLatitude;
    maxLatitude = point.latitude > maxLatitude ? point.latitude : maxLatitude;
    minLongitude = point.longitude < minLongitude
        ? point.longitude
        : minLongitude;
    maxLongitude = point.longitude > maxLongitude
        ? point.longitude
        : maxLongitude;
  }

  final latitudeSpan = maxLatitude - minLatitude;
  final longitudeSpan = maxLongitude - minLongitude;
  if (!latitudeSpan.isFinite ||
      !longitudeSpan.isFinite ||
      (latitudeSpan.abs() < 0.000001 && longitudeSpan.abs() < 0.000001)) {
    return null;
  }

  return LatLngBounds.fromPoints(points);
}

class _FullscreenWorkoutRouteMap extends StatelessWidget {
  const _FullscreenWorkoutRouteMap({required this.route, required this.title});

  final List<WorkoutRoutePoint> route;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = _buildValidLatLngs(route);
    final bounds = _buildSafeBounds(points);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: points.isEmpty
          ? const SizedBox.shrink()
          : _WorkoutRouteMapCanvas(
              points: points,
              bounds: bounds,
              routeColor: colorScheme.primary,
              startColor: colorScheme.secondary,
            ),
    );
  }
}

class _WorkoutRouteMapCanvas extends StatelessWidget {
  const _WorkoutRouteMapCanvas({
    required this.points,
    required this.bounds,
    required this.routeColor,
    required this.startColor,
  });

  final List<LatLng> points;
  final LatLngBounds? bounds;
  final Color routeColor;
  final Color startColor;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: points.last,
        initialZoom: points.length == 1 ? 16 : 15,
        initialCameraFit: bounds == null
            ? null
            : CameraFit.bounds(
                bounds: bounds!,
                padding: const EdgeInsets.all(36),
              ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.liga_gym_app',
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(points: points, strokeWidth: 5, color: routeColor),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: points.first,
              width: 36,
              height: 36,
              child: _RouteMarker(color: startColor, icon: Icons.flag_rounded),
            ),
            Marker(
              point: points.last,
              width: 42,
              height: 42,
              child: _RouteMarker(
                color: routeColor,
                icon: Icons.location_on_rounded,
              ),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _RouteMapPlaceholder extends StatelessWidget {
  const _RouteMapPlaceholder({
    required this.height,
    required this.icon,
    required this.message,
  });

  final double height;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
