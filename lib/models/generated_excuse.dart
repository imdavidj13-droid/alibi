enum FollowUpRisk { low, medium, high }

class GeneratedExcuse {
  const GeneratedExcuse({
    required this.text,
    required this.situation,
    required this.tone,
    required this.believability,
    required this.followUpRisk,
  });

  final String text;
  final String situation;
  final String tone;
  final num believability;
  final FollowUpRisk followUpRisk;

  String get followUpRiskLabel => switch (followUpRisk) {
    FollowUpRisk.low => 'LOW',
    FollowUpRisk.medium => 'MEDIUM',
    FollowUpRisk.high => 'HIGH',
  };
}
