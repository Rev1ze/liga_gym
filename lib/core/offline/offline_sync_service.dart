import 'offline_sync_record.dart';

abstract class OfflineSyncService<T extends OfflineSyncRecord> {
  const OfflineSyncService();

  Future<void> syncDataWithServer({required String userId});

  T resolveConflicts({required T localRecord, T? remoteRecord}) {
    final remote = remoteRecord;
    if (remote == null) {
      return localRecord;
    }

    final localWins = !localRecord.lastModifiedAt.isBefore(
      remote.lastModifiedAt,
    );
    return localWins ? localRecord : remote;
  }
}
