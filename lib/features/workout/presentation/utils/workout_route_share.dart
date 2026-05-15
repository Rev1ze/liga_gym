import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_route_point.dart';
import 'workout_formatters.dart';

Future<void> shareWorkoutRoute({
  required BuildContext context,
  required Workout workout,
  required String missingRouteMessage,
  required String subject,
  required String routeTitle,
}) async {
  final route = workout.route
      .where((point) => point.hasValidCoordinates)
      .toList(growable: false);

  if (route.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(missingRouteMessage)));
    return;
  }

  final renderBox = context.findRenderObject() as RenderBox?;
  final directory = await getTemporaryDirectory();
  final fileName =
      'liga_gym_route_${DateFormat('yyyyMMdd_HHmm').format(workout.startedAt)}.gpx';
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(_buildGpx(workout, route), flush: true);

  if (!context.mounted) {
    return;
  }

  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path)],
      subject: subject,
      text: _buildShareText(workout, route, routeTitle),
      sharePositionOrigin: renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size,
    ),
  );
}

String _buildShareText(
  Workout workout,
  List<WorkoutRoutePoint> route,
  String routeTitle,
) {
  final firstPoint = route.first;
  final lastPoint = route.last;
  final mapsUrl =
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${firstPoint.latitude},${firstPoint.longitude}'
      '&destination=${lastPoint.latitude},${lastPoint.longitude}'
      '&travelmode=walking';

  return [
    routeTitle,
    DateFormat('dd.MM.yyyy HH:mm').format(workout.startedAt),
    formatWorkoutDistance(workout.distanceMeters),
    formatWorkoutDuration(workout.duration),
    mapsUrl,
  ].join('\n');
}

String _buildGpx(Workout workout, List<WorkoutRoutePoint> route) {
  final points = route.map(_buildGpxPoint).join('\n');
  final name = _xmlEscape(
    'Liga Gym ${DateFormat('dd.MM.yyyy HH:mm').format(workout.startedAt)}',
  );

  return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Liga Gym" xmlns="http://www.topografix.com/GPX/1/1">
  <trk>
    <name>$name</name>
    <trkseg>
$points
    </trkseg>
  </trk>
</gpx>
''';
}

String _buildGpxPoint(WorkoutRoutePoint point) {
  return '      <trkpt lat="${point.latitude}" lon="${point.longitude}"><time>${point.recordedAt.toUtc().toIso8601String()}</time></trkpt>';
}

String _xmlEscape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
