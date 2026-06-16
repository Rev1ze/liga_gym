class CustomExercise {
  const CustomExercise({
    required this.id,
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
    required this.isFavorite,
    required this.createdAt,
  });

  final String id;
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
  final bool isFavorite;
  final DateTime createdAt;

  CustomExercise copyWith({
    String? id,
    String? title,
    String? description,
    String? muscleGroups,
    String? equipment,
    String? techniqueText,
    String? defaultCategory,
    String? customCategory,
    String? avatarDataUrl,
    String? iconName,
    List<String>? photoDataUrls,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return CustomExercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      equipment: equipment ?? this.equipment,
      techniqueText: techniqueText ?? this.techniqueText,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      customCategory: customCategory ?? this.customCategory,
      avatarDataUrl: avatarDataUrl ?? this.avatarDataUrl,
      iconName: iconName ?? this.iconName,
      photoDataUrls: photoDataUrls ?? this.photoDataUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'muscleGroups': muscleGroups,
      'equipment': equipment,
      'techniqueText': techniqueText,
      'defaultCategory': defaultCategory,
      'customCategory': customCategory,
      'avatarDataUrl': avatarDataUrl,
      'iconName': iconName,
      'photoDataUrls': photoDataUrls,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomExercise.fromJson(Map<String, Object?> json) {
    return CustomExercise(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      muscleGroups: json['muscleGroups'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      techniqueText: json['techniqueText'] as String? ?? '',
      defaultCategory: json['defaultCategory'] as String? ?? 'strength',
      customCategory: json['customCategory'] as String? ?? '',
      avatarDataUrl: json['avatarDataUrl'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'dumbbell',
      photoDataUrls:
          (json['photoDataUrls'] as List<Object?>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
