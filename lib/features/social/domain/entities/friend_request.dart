import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromDisplayName,
    required this.fromEmail,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return FriendRequest(
      id: document.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      fromDisplayName: data['fromDisplayName'] as String? ?? 'Athlete',
      fromEmail: data['fromEmail'] as String? ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromDisplayName;
  final String fromEmail;
  final FriendRequestStatus status;
  final DateTime? createdAt;
}
