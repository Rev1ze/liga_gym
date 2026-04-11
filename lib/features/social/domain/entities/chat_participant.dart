import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_member_role.dart';

class ChatParticipant {
  const ChatParticipant({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.canRemoveMessages,
    required this.canRemoveUsers,
    required this.joinedAt,
    this.city,
  });

  factory ChatParticipant.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ChatParticipant.fromMap(document.id, document.data());
  }

  factory ChatParticipant.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ChatParticipant.fromMap(document.id, document.data() ?? const {});
  }

  factory ChatParticipant.fromMap(String userId, Map<String, dynamic> data) {
    final joinedAt = data['joinedAt'] as Timestamp?;
    return ChatParticipant(
      userId: userId,
      displayName: data['displayName'] as String? ?? 'Athlete',
      city: (data['city'] as String?)?.trim(),
      role: _parseRole(data['role'] as String?),
      canRemoveMessages: data['canRemoveMessages'] as bool? ?? false,
      canRemoveUsers: data['canRemoveUsers'] as bool? ?? false,
      joinedAt: joinedAt?.toDate() ?? DateTime.now(),
    );
  }

  final String userId;
  final String displayName;
  final String? city;
  final ChatMemberRole role;
  final bool canRemoveMessages;
  final bool canRemoveUsers;
  final DateTime joinedAt;

  bool get isAdmin => role == ChatMemberRole.admin;
  bool get isModerator => role == ChatMemberRole.moderator;

  static ChatMemberRole _parseRole(String? value) {
    return ChatMemberRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => ChatMemberRole.member,
    );
  }
}
