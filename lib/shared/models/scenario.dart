class Scenario {
  final String id;
  final String title;
  final String prompt;
  final String firstMessage;
  final int recommendedDuration;
  final bool enabled;

  const Scenario({
    required this.id,
    required this.title,
    required this.prompt,
    required this.firstMessage,
    this.recommendedDuration = 30,
    this.enabled = true,
  });
}
