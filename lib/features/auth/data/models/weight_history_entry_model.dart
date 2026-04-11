import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weight_history_entry.dart';

class WeightHistoryEntryModel extends WeightHistoryEntry {
  const WeightHistoryEntryModel({
    required super.userId,
    required super.recordedAt,
    required super.weightKg,
  });

  factory WeightHistoryEntryModel.fromFirestore(
    String userId,
    Map<String, Object?> data,
  ) {
    return WeightHistoryEntryModel(
      userId: userId,
      recordedAt:
          (data['recordedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      weightKg: ((data['weightKg'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'recordedAt': Timestamp.fromDate(recordedAt),
      'weightKg': weightKg,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
