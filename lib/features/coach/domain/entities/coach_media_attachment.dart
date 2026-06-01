enum CoachMediaType { image, video }

class CoachMediaAttachment {
  const CoachMediaAttachment({
    required this.url,
    required this.name,
    required this.type,
  });

  final String url;
  final String name;
  final CoachMediaType type;
}
