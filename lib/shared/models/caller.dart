class Caller {
  final String id;
  final String name;
  final String voiceId;
  final String? avatarUrl;
  final String persona;
  final String emoji;

  const Caller({
    required this.id,
    required this.name,
    required this.voiceId,
    this.avatarUrl,
    required this.persona,
    required this.emoji,
  });
}
