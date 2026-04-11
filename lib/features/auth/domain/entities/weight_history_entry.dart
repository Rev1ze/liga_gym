class WeightHistoryEntry {
  const WeightHistoryEntry({
    required this.userId,
    required this.recordedAt,
    required this.weightKg,
  });

  final String userId;
  final DateTime recordedAt;
  final double weightKg;
}
