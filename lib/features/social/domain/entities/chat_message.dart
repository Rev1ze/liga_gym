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
    this.type = ChatMessageType.text,
    this.sharedResult,
    this.sharedExercise,
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
      type: ChatMessageType.fromName(data['type'] as String?),
      sharedResult: SharedChatResult.fromMap(data['sharedResult']),
      sharedExercise: SharedChatExercise.tryFromMap(data['sharedExercise']),
    );
  }

  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String? senderCity;
  final String message;
  final DateTime sentAt;
  final ChatMessageType type;
  final SharedChatResult? sharedResult;
  final SharedChatExercise? sharedExercise;
}

enum ChatMessageType {
  text,
  dailyResult,
  sharedExercise;

  static ChatMessageType fromName(String? value) {
    return switch (value) {
      'daily_result' => ChatMessageType.dailyResult,
      'shared_exercise' => ChatMessageType.sharedExercise,
      _ => ChatMessageType.text,
    };
  }

  String get firestoreName {
    return switch (this) {
      ChatMessageType.text => 'text',
      ChatMessageType.dailyResult => 'daily_result',
      ChatMessageType.sharedExercise => 'shared_exercise',
    };
  }
}

class SharedChatResult {
  const SharedChatResult({
    required this.title,
    required this.date,
    required this.steps,
    required this.caloriesBurned,
    required this.caloriesConsumed,
    required this.workoutsCount,
    required this.workoutMinutes,
    required this.progressPercent,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  factory SharedChatResult.fromMap(Object? raw) {
    final data = raw is Map ? raw : const <Object?, Object?>{};
    final timestamp = data['date'] as Timestamp?;

    return SharedChatResult(
      title: data['title'] as String? ?? '',
      date: timestamp?.toDate() ?? DateTime.now(),
      steps: (data['steps'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toDouble() ?? 0,
      caloriesConsumed: (data['caloriesConsumed'] as num?)?.toDouble() ?? 0,
      workoutsCount: (data['workoutsCount'] as num?)?.toInt() ?? 0,
      workoutMinutes: (data['workoutMinutes'] as num?)?.toInt() ?? 0,
      progressPercent: (data['progressPercent'] as num?)?.toInt() ?? 0,
      proteins: (data['proteins'] as num?)?.toDouble() ?? 0,
      fats: (data['fats'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
    );
  }

  final String title;
  final DateTime date;
  final int steps;
  final double caloriesBurned;
  final double caloriesConsumed;
  final int workoutsCount;
  final int workoutMinutes;
  final int progressPercent;
  final double proteins;
  final double fats;
  final double carbs;
}

class SharedChatExercise {
  const SharedChatExercise({
    required this.sourceExerciseId,
    required this.title,
    required this.description,
    required this.muscleGroups,
    required this.equipment,
    required this.techniqueText,
    required this.defaultCategory,
    required this.customCategory,
    required this.avatarDataUrl,
    required this.iconName,
    required this.photoDataUrls,
  });

  static SharedChatExercise? tryFromMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return SharedChatExercise(
      sourceExerciseId: raw['sourceExerciseId'] as String? ?? '',
      title: raw['title'] as String? ?? '',
      description: raw['description'] as String? ?? '',
      muscleGroups: raw['muscleGroups'] as String? ?? '',
      equipment: raw['equipment'] as String? ?? '',
      techniqueText: raw['techniqueText'] as String? ?? '',
      defaultCategory: raw['defaultCategory'] as String? ?? 'strength',
      customCategory: raw['customCategory'] as String? ?? '',
      avatarDataUrl: raw['avatarDataUrl'] as String? ?? '',
      iconName: raw['iconName'] as String? ?? 'dumbbell',
      photoDataUrls:
          (raw['photoDataUrls'] as List<Object?>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
    );
  }

  final String sourceExerciseId;
  final String title;
  final String description;
  final String muscleGroups;
  final String equipment;
  final String techniqueText;
  final String defaultCategory;
  final String customCategory;
  final String avatarDataUrl;
  final String iconName;
  final List<String> photoDataUrls;
}
