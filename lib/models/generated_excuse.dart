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

  Map<String, dynamic> toJson() => {
    'text': text,
    'situation': situation,
    'tone': tone,
    'believability': believability,
    'followUpRisk': followUpRisk.name,
  };

  factory GeneratedExcuse.fromJson(Map<String, dynamic> json) {
    return GeneratedExcuse(
      text: json['text'] as String? ?? '',
      situation: json['situation'] as String? ?? 'Plans',
      tone: json['tone'] as String? ?? 'Believable',
      believability: json['believability'] as num? ?? 75,
      followUpRisk: FollowUpRisk.values.firstWhere(
        (value) => value.name == json['followUpRisk'],
        orElse: () => FollowUpRisk.medium,
      ),
    );
  }
}
