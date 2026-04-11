import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    this.senderCity,
    required this.message,
    required this.sentAt,
  });

  factory ChatMessage.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['sentAt'] as Timestamp?;

    return ChatMessage(
      id: document.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Athlete',
      senderEmail: data['senderEmail'] as String? ?? '',
      senderCity: (data['senderCity'] as String?)?.trim(),
      message: data['message'] as String? ?? '',
      sentAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderCity;
  final String message;
  final DateTime sentAt;
}
