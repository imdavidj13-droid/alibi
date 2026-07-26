import 'dart:math';

import '../models/excuse_length.dart';
import '../models/generated_excuse.dart';

class ExcuseGenerator {
  ExcuseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, _ShuffleBag<_Scenario>> _scenarioBags = {};
  final Map<String, _ShuffleBag<String>> _textBags = {};
  final List<String> _recent = [];

  static const situations = [
    'Work',
    'Plans',
    'Family',
    'Dating',
    'School',
    'Appointments',
    'Gym',
    'Neighbours',
    'Deliveries',
  ];

  static const tones = [
    'Believable',
    'Dramatic',
    'Brutally honest',
    'Ridiculous',
  ];

  GeneratedExcuse generate({
    required String situation,
    required String tone,
    ExcuseLength length = ExcuseLength.standard,
    String detail = '',
    bool safeMode = true,
  }) {
    final resolvedSituation =
        situations.contains(situation) ? situation : 'Plans';
    final resolvedTone = tones.contains(tone) ? tone : 'Believable';
    final cleanDetail = _cleanDetail(detail);

    var result = _build(
      situation: resolvedSituation,
      tone: resolvedTone,
      length: length,
      detail: cleanDetail,
      safeMode: safeMode,
    );

    for (var attempt = 0; attempt < 5 && _recent.contains(result.text); attempt++) {
      result = _build(
        situation: resolvedSituation,
        tone: resolvedTone,
        length: length,
        detail: cleanDetail,
        safeMode: safeMode,
      );
    }

    _recent.insert(0, result.text);
    if (_recent.length > 80) _recent.removeLast();
    return result;
  }

  GeneratedExcuse _build({
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
  }) {
    final scenario = (_scenarioBags[situation] ??=
            _ShuffleBag<_Scenario>(_scenarios[situation]!, _random))
        .next();
    final detailClause = detail.isEmpty ? '' : _detailClause(detail);

    final text = switch (tone) {
      'Dramatic' => _dramaticMessage(scenario, detailClause, length, safeMode),
      'Brutally honest' => _honestMessage(scenario, detailClause, length),
      'Ridiculous' =>
        _ridiculousMessage(scenario, detailClause, length, safeMode),
      _ => _believableMessage(scenario, detailClause, length),
    };

    final score = _score(
      tone: tone,
      length: length,
      detail: detail,
      safeMode: safeMode,
      scenario: scenario,
    );

    return GeneratedExcuse(
      text: _clean(text),
      situation: situation,
      tone: tone,
      believability: score.believability,
      followUpRisk: score.risk,
    );
  }

  String _believableMessage(
    _Scenario scenario,
    String detailClause,
    ExcuseLength length,
  ) {
    final opening = _nextText('believable-opening', const [
      'I’m sorry for the short notice, but',
      'I was hoping I could still make this work, but',
      'I’ve tried to avoid changing the plan, but',
      'Unfortunately,',
      'I need to be realistic and say',
    ]);
    final reason = '$opening ${scenario.believableReason}$detailClause.';

    return switch (length) {
      ExcuseLength.short => '$reason ${scenario.shortClosing}',
      ExcuseLength.standard =>
        '$reason ${scenario.impact} ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$reason ${scenario.impact} ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _dramaticMessage(
    _Scenario scenario,
    String detailClause,
    ExcuseLength length,
    bool safeMode,
  ) {
    final opening = _nextText('dramatic-opening', const [
      'The day has unravelled much faster than expected, and',
      'A manageable problem has turned into a complete mess, and',
      'Everything has decided to go wrong at once, and',
      'I wish I were exaggerating, but',
      'What looked manageable earlier is no longer manageable, and',
    ]);
    final reason = '$opening ${scenario.dramaticReason}$detailClause.';
    final impact = safeMode ? scenario.impact : scenario.dramaticImpact;

    return switch (length) {
      ExcuseLength.short => '$reason ${scenario.shortClosing}',
      ExcuseLength.standard => '$reason $impact ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$reason $impact ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _honestMessage(
    _Scenario scenario,
    String detailClause,
    ExcuseLength length,
  ) {
    final opening = _nextText('honest-opening', const [
      'I’m going to be completely honest:',
      'Rather than invent a story, the truth is that',
      'I owe you a straightforward answer:',
      'There is no dramatic emergency;',
      'I’m not going to dress this up:',
    ]);
    final reason = '$opening ${scenario.honestReason}$detailClause.';

    return switch (length) {
      ExcuseLength.short => '$reason ${scenario.honestClosing}',
      ExcuseLength.standard =>
        '$reason ${scenario.honestImpact} ${scenario.honestClosing}',
      ExcuseLength.detailed =>
        '$reason ${scenario.honestImpact} ${scenario.reassurance} ${scenario.honestClosing}',
    };
  }

  String _ridiculousMessage(
    _Scenario scenario,
    String detailClause,
    ExcuseLength length,
    bool safeMode,
  ) {
    final opening = _nextText('ridiculous-opening', const [
      'Reality has abandoned quality control, and',
      'The universe has become unnecessarily involved, and',
      'I appear to be trapped in a low-budget disaster film because',
      'Common sense is no longer in charge, and',
      'Against every law of probability,',
    ]);
    final reason = '$opening ${scenario.ridiculousReason}$detailClause.';
    final impact = safeMode ? scenario.dramaticImpact : scenario.ridiculousImpact;

    return switch (length) {
      ExcuseLength.short => '$reason ${scenario.shortClosing}',
      ExcuseLength.standard => '$reason $impact ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$reason $impact ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _detailClause(String detail) {
    final kind = _classifyDetail(detail);
    final subject = _normaliseDetail(detail, kind);
    final lower = subject.toLowerCase();

    if (RegExp(r'\b(dog|cat|pet)\b').hasMatch(lower)) {
      return ', and I also need to look after $subject today';
    }

    return switch (kind) {
      _DetailKind.personOrGroup =>
        ', while I also need to stay available because of $subject',
      _DetailKind.place => ', with a related issue at $subject',
      _DetailKind.object => ', with $subject also needing my attention',
      _DetailKind.event =>
        ', because the timing of $subject has also changed',
      _DetailKind.subject => ', with $subject also involved',
    };
  }

  _DetailKind _classifyDetail(String detail) {
    final lower = detail.toLowerCase();

    if (RegExp(
      r'\b(meeting|appointment|match|game|concert|event|delivery|shift|training|lesson|interview|visit)\b',
    ).hasMatch(lower)) {
      return _DetailKind.event;
    }

    if (RegExp(
      r'\b(home|house|office|school|hospital|station|airport|garage|venue|london|town|city)\b',
    ).hasMatch(lower)) {
      return _DetailKind.place;
    }

    if (RegExp(r'^(my|the|a|an)\s+').hasMatch(lower) ||
        RegExp(
          r'\b(car|boiler|phone|laptop|pet|dog|cat|parcel|key|keys|internet)\b',
        ).hasMatch(lower)) {
      return _DetailKind.object;
    }

    if (_looksLikeName(detail) ||
        RegExp(
          r'\b(mum|mom|dad|brother|sister|friend|manager|teacher|doctor|team|women|united|fc)\b',
        ).hasMatch(lower)) {
      return _DetailKind.personOrGroup;
    }

    return _DetailKind.subject;
  }

  String _normaliseDetail(String detail, _DetailKind kind) {
    var result = detail;

    result = result.replaceAllMapped(
      RegExp(r"\bcalled\s+([a-z][a-z'-]*)", caseSensitive: false),
      (match) {
        final name = match.group(1)!;
        return 'called ${name[0].toUpperCase()}${name.substring(1).toLowerCase()}';
      },
    );

    if (kind != _DetailKind.personOrGroup) return result;

    final lower = result.toLowerCase();
    final shouldTitleCase = _looksLikeName(result) ||
        RegExp(r'\b(women|united|city|fc|team)\b').hasMatch(lower);
    if (!shouldTitleCase) return result;

    return result
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  bool _looksLikeName(String detail) {
    final words = detail.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty || words.length > 5) return false;
    return words.every(
      (word) => RegExp(r"^[A-Z][A-Za-z'-]*$").hasMatch(word),
    );
  }

  _Score _score({
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
    required _Scenario scenario,
  }) {
    var believability = switch (tone) {
      'Believable' => scenario.baseBelievability,
      'Dramatic' => scenario.baseBelievability - 16,
      'Brutally honest' => 94,
      'Ridiculous' => 22,
      _ => 75,
    };

    var riskPoints = switch (tone) {
      'Believable' => 1,
      'Dramatic' => 4,
      'Brutally honest' => 2,
      'Ridiculous' => 6,
      _ => 3,
    };

    switch (length) {
      case ExcuseLength.short:
        believability += 2;
        riskPoints -= 1;
      case ExcuseLength.standard:
        break;
      case ExcuseLength.detailed:
        believability -= 2;
        riskPoints += 1;
    }

    if (detail.isNotEmpty) {
      final words = detail.split(' ').length;
      if (words <= 5) believability += 1;
      if (words > 10) {
        believability -= 7;
        riskPoints += 2;
      }
      if (_looksUnusual(detail)) {
        if (tone != 'Ridiculous') believability -= 7;
        riskPoints += 1;
      }
    }

    if (safeMode) {
      believability += tone == 'Ridiculous' ? 1 : 3;
      riskPoints -= 1;
    }

    believability += _random.nextInt(5) - 2;
    final clampedRisk = riskPoints.clamp(0, 8);

    return _Score(
      believability.clamp(1, 99),
      clampedRisk <= 2
          ? FollowUpRisk.low
          : clampedRisk <= 4
              ? FollowUpRisk.medium
              : FollowUpRisk.high,
    );
  }

  bool _looksUnusual(String detail) {
    return RegExp(
      r'\b(alien|dragon|zombie|pigeon|spaceship|pirate|ghost|unicorn|volcano|secret agent)\b',
      caseSensitive: false,
    ).hasMatch(detail);
  }

  String _cleanDetail(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?,;:]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  String _nextText(String key, List<String> values) {
    return (_textBags[key] ??= _ShuffleBag<String>(values, _random)).next();
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(' .', '.')
      .replaceAll('..', '.')
      .trim();

  static const _scenarios = <String, List<_Scenario>>{
    'Work': [
      _Scenario(
        believableReason:
            'a repair issue at home needs someone here until it is resolved',
        dramaticReason:
            'a repair issue at home has escalated and now needs constant attention',
        honestReason: 'I am too depleted to do useful work today',
        ridiculousReason:
            'my home has become an unofficial command centre for a problem nobody understands',
        impact: 'I cannot work reliably while I am dealing with it.',
        dramaticImpact:
            'Every attempt to fix it has introduced another problem.',
        ridiculousImpact:
            'I have apparently been promoted to emergency facilities manager without my consent.',
        reassurance:
            'I will catch up on anything urgent as soon as I am able.',
        shortClosing: 'I need to step away today.',
        standardClosing:
            'I will send an update when the situation is clearer.',
        honestImpact:
            'Pretending otherwise would only create poor work and more problems later.',
        honestClosing: 'I will take responsibility for catching up properly.',
        baseBelievability: 88,
      ),
      _Scenario(
        believableReason:
            'my transport has failed and I do not have a reliable alternative',
        dramaticReason:
            'my entire journey has collapsed with no workable alternative',
        honestReason:
            'I have not organised myself well enough to get there on time',
        ridiculousReason:
            'my journey has been defeated by transport, timing and one extremely confident pigeon',
        impact: 'There is no realistic way for me to arrive when expected.',
        dramaticImpact:
            'Every replacement option has failed almost immediately.',
        ridiculousImpact:
            'Public transport and basic probability have both declined to cooperate.',
        reassurance: 'I will remain available by phone where possible.',
        shortClosing: 'I will not make it in today.',
        standardClosing: 'I am sorry for the disruption.',
        honestImpact: 'That is my responsibility rather than anyone else’s.',
        honestClosing: 'I will plan this better next time.',
        baseBelievability: 86,
      ),
    ],
    'Plans': [
      _Scenario(
        believableReason: 'something time-sensitive has come up at home',
        dramaticReason:
            'a problem at home has grown far beyond what I expected',
        honestReason:
            'I do not have the energy to socialise properly tonight',
        ridiculousReason:
            'my evening has been claimed by a household crisis with no respect for my plans',
        impact: 'I need to stay here until it is dealt with.',
        dramaticImpact:
            'Leaving now would make the situation considerably worse.',
        ridiculousImpact:
            'I am apparently the only available adult with access to the correct key.',
        reassurance: 'I would rather rearrange than keep you waiting.',
        shortClosing: 'Can we move this to another day?',
        standardClosing: 'I am sorry for cancelling so late.',
        honestImpact:
            'Forcing myself through the evening would not be fair to either of us.',
        honestClosing:
            'I would rather rearrange and be properly present.',
        baseBelievability: 86,
      ),
    ],
    'Family': [
      _Scenario(
        believableReason:
            'I need a quiet evening to deal with something personal',
        dramaticReason:
            'a personal situation has become emotionally overwhelming today',
        honestReason: 'I need time alone and should have said that sooner',
        ridiculousReason:
            'my emotional battery has reached a percentage normally reserved for emergency warnings',
        impact: 'I am not in the right state to be good company.',
        dramaticImpact:
            'Trying to continue as normal would only make everything harder.',
        ridiculousImpact:
            'Any further social interaction may cause the system to shut down completely.',
        reassurance: 'I will check in properly once I have had some space.',
        shortClosing: 'I need to stay home tonight.',
        standardClosing: 'Thank you for understanding.',
        honestImpact:
            'I would rather say no clearly than turn up resentful or distracted.',
        honestClosing: 'I hope we can rearrange soon.',
        baseBelievability: 84,
      ),
    ],
    'Dating': [
      _Scenario(
        believableReason:
            'I am not feeling well enough to be good company tonight',
        dramaticReason:
            'I have gone from slightly unwell to completely unable to face the evening',
        honestReason:
            'I am not in the right frame of mind for a date tonight',
        ridiculousReason:
            'my body has filed a formal objection to leaving the house',
        impact: 'I would not be fully present if we met.',
        dramaticImpact:
            'Trying to push through would make the evening worse for both of us.',
        ridiculousImpact:
            'Even my shoes appear to have withdrawn their support.',
        reassurance:
            'I would rather choose another night when I can enjoy it properly.',
        shortClosing: 'Can we reschedule?',
        standardClosing: 'I am sorry for the late change.',
        honestImpact:
            'That is about my capacity today, not a lack of interest.',
        honestClosing: 'I would still like to arrange another time.',
        baseBelievability: 82,
      ),
    ],
    'School': [
      _Scenario(
        believableReason:
            'I am not well enough to concentrate properly today',
        dramaticReason:
            'I have become much more unwell overnight and cannot focus properly',
        honestReason:
            'I have not prepared properly and need to be honest about that',
        ridiculousReason:
            'my preparation has disappeared into the same dimension as missing pens and completed homework',
        impact: 'Attending would not result in useful work.',
        dramaticImpact:
            'Trying to continue would leave me further behind rather than helping.',
        ridiculousImpact:
            'My notes and my attention span have both left without forwarding addresses.',
        reassurance:
            'I will review the missed material and catch up as soon as possible.',
        shortClosing: 'I will not be able to attend today.',
        standardClosing:
            'Please send over anything important that I miss.',
        honestImpact:
            'That is my responsibility, and I need to correct it directly.',
        honestClosing:
            'I will take responsibility for catching up properly.',
        baseBelievability: 87,
      ),
    ],
    'Appointments': [
      _Scenario(
        believableReason:
            'an urgent commitment now clashes with the appointment',
        dramaticReason:
            'an urgent commitment has moved without warning and taken over the time completely',
        honestReason: 'I have double-booked myself and only just noticed',
        ridiculousReason:
            'my calendar has apparently developed free will and scheduled two realities at once',
        impact: 'I cannot attend at the original time.',
        dramaticImpact:
            'There is no practical way to resolve both commitments today.',
        ridiculousImpact:
            'Unless I discover time travel, one booking has to move.',
        reassurance:
            'I would like to rearrange rather than leave the slot unused.',
        shortClosing: 'Can we reschedule?',
        standardClosing: 'I apologise for the inconvenience.',
        honestImpact:
            'This is my scheduling mistake, not a problem with the appointment.',
        honestClosing:
            'I will make sure the replacement time is properly protected.',
        baseBelievability: 89,
      ),
    ],
    'Gym': [
      _Scenario(
        believableReason:
            'I am feeling too run down to train safely today',
        dramaticReason:
            'my energy has disappeared and training now feels actively unwise',
        honestReason: 'I do not want to train today and need the rest more',
        ridiculousReason:
            'my motivation has left the building and taken my coordination with it',
        impact:
            'Pushing through would probably set me back rather than help.',
        dramaticImpact:
            'Even a light session would be more punishment than progress.',
        ridiculousImpact:
            'The dumbbells have won without needing to leave the rack.',
        reassurance:
            'I will return when I can train properly rather than force it.',
        shortClosing: 'I am skipping today’s session.',
        standardClosing: 'I will rearrange the session.',
        honestImpact:
            'I would rather admit that than invent a medical emergency.',
        honestClosing: 'I will get back to the routine next time.',
        baseBelievability: 85,
      ),
    ],
    'Neighbours': [
      _Scenario(
        believableReason:
            'a problem at home needs my attention before it affects anyone else',
        dramaticReason:
            'a household problem is beginning to affect the surrounding property',
        honestReason:
            'I have delayed dealing with a problem and now need to sort it out',
        ridiculousReason:
            'my house has begun negotiating directly with the neighbourhood group chat',
        impact:
            'I need to remain here until I know it is contained.',
        dramaticImpact:
            'Ignoring it now could create a much larger problem.',
        ridiculousImpact:
            'At least one person is wearing a high-visibility jacket without explanation.',
        reassurance:
            'I will update anyone affected as soon as I know more.',
        shortClosing: 'I need to deal with this now.',
        standardClosing: 'I am sorry for the disruption.',
        honestImpact: 'This is the result of me leaving it too long.',
        honestClosing: 'I will deal with it properly today.',
        baseBelievability: 85,
      ),
    ],
    'Deliveries': [
      _Scenario(
        believableReason:
            'an essential delivery has been moved into a time I cannot leave unattended',
        dramaticReason:
            'an essential delivery has shifted repeatedly and now controls the entire day',
        honestReason:
            'I agreed to a delivery window without checking the rest of my plans',
        ridiculousReason:
            'a parcel has gained complete authority over my movements',
        impact: 'I need to remain available until it arrives.',
        dramaticImpact:
            'Missing it would restart the entire process from the beginning.',
        ridiculousImpact:
            'The tracking page now knows more about my day than I do.',
        reassurance:
            'I will let you know as soon as the delivery is complete.',
        shortClosing: 'I cannot leave until it arrives.',
        standardClosing: 'I am sorry for the inconvenience.',
        honestImpact: 'This is poor planning on my part.',
        honestClosing: 'I will avoid booking it this way again.',
        baseBelievability: 88,
      ),
    ],
  };
}

enum _DetailKind { personOrGroup, place, object, event, subject }

class _Scenario {
  const _Scenario({
    required this.believableReason,
    required this.dramaticReason,
    required this.honestReason,
    required this.ridiculousReason,
    required this.impact,
    required this.dramaticImpact,
    required this.ridiculousImpact,
    required this.reassurance,
    required this.shortClosing,
    required this.standardClosing,
    required this.honestImpact,
    required this.honestClosing,
    required this.baseBelievability,
  });

  final String believableReason;
  final String dramaticReason;
  final String honestReason;
  final String ridiculousReason;
  final String impact;
  final String dramaticImpact;
  final String ridiculousImpact;
  final String reassurance;
  final String shortClosing;
  final String standardClosing;
  final String honestImpact;
  final String honestClosing;
  final int baseBelievability;
}

class _Score {
  const _Score(this.believability, this.risk);

  final num believability;
  final FollowUpRisk risk;
}

class _ShuffleBag<T> {
  _ShuffleBag(List<T> source, this.random) : _source = List<T>.from(source) {
    _refill();
  }

  final List<T> _source;
  final Random random;
  final List<T> _remaining = [];
  T? _last;

  T next() {
    if (_remaining.isEmpty) _refill();
    final value = _remaining.removeLast();
    _last = value;
    return value;
  }

  void _refill() {
    _remaining
      ..clear()
      ..addAll(_source)
      ..shuffle(random);

    if (_last != null &&
        _remaining.length > 1 &&
        _remaining.last == _last) {
      final swapIndex = random.nextInt(_remaining.length - 1);
      final temporary = _remaining[swapIndex];
      _remaining[swapIndex] = _remaining.last;
      _remaining[_remaining.length - 1] = temporary;
    }
  }
}
