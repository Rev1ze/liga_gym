import 'package:flutter/material.dart';

class AnalyticsRangeQuery {
  const AnalyticsRangeQuery({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  AnalyticsRangeQuery normalized() {
    return AnalyticsRangeQuery(
      from: DateUtils.dateOnly(from),
      to: DateUtils.dateOnly(to),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnalyticsRangeQuery &&
        DateUtils.isSameDay(from, other.from) &&
        DateUtils.isSameDay(to, other.to);
  }

  @override
  int get hashCode => Object.hash(
    DateUtils.dateOnly(from).millisecondsSinceEpoch,
    DateUtils.dateOnly(to).millisecondsSinceEpoch,
  );
}
