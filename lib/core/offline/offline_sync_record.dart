abstract interface class OfflineSyncRecord {
  String get id;

  bool get isSynced;

  DateTime get lastModifiedAt;
}
