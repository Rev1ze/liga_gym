import 'package:cloud_firestore/cloud_firestore.dart';

class FriendChatRoom {
  const FriendChatRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.memberCount,
    required this.createdAt,
    this.lastMessageAt,
  });

  factory FriendChatRoom.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return FriendChatRoom.fromMap(document.id, document.data() ?? const {});
  }

  factory FriendChatRoom.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'] as Timestamp?;
    final lastMessageAt = data['lastMessageAt'] as Timestamp?;

    return FriendChatRoom(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt?.toDate() ?? DateTime.now(),
      lastMessageAt: lastMessageAt?.toDate(),
    );
  }

  final String id;
  final String title;
  final String description;
  final String createdBy;
  final String createdByName;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
}
