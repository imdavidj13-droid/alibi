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
    final resolvedSituation = situations.contains(situation) ? situation : 'Plans';
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

    final detailPhrase = detail.isEmpty
        ? null
        : _detailPhrase(
            detail: detail,
            situation: situation,
            scenario: scenario,
          );

    final text = switch (tone) {
      'Dramatic' => _dramaticMessage(
          situation,
          scenario,
          detailPhrase,
          length,
          safeMode,
        ),
      'Brutally honest' => _honestMessage(
          situation,
          scenario,
          detailPhrase,
          length,
        ),
      'Ridiculous' => _ridiculousMessage(
          situation,
          scenario,
          detailPhrase,
          length,
          safeMode,
        ),
      _ => _believableMessage(
          situation,
          scenario,
          detailPhrase,
          length,
        ),
    };

    final score = _score(
      situation: situation,
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
    String situation,
    _Scenario scenario,
    String? detail,
    ExcuseLength length,
  ) {
    final opening = _nextText('believable-opening', const [
      'I’m sorry for the short notice.',
      'I was hoping I could still make this work.',
      'I’ve tried to avoid changing the plan.',
      'I wanted to let you know as early as I could.',
      'Unfortunately, something has changed today.',
    ]);

    final reason = detail == null
        ? scenario.believableReason
        : '${scenario.believableReason} $detail';

    return switch (length) {
      ExcuseLength.short => '$opening $reason ${scenario.shortClosing}',
      ExcuseLength.standard =>
        '$opening $reason ${scenario.impact} ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$opening $reason ${scenario.impact} ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _dramaticMessage(
    String situation,
    _Scenario scenario,
    String? detail,
    ExcuseLength length,
    bool safeMode,
  ) {
    final opening = _nextText('dramatic-opening', const [
      'I wish I were exaggerating.',
      'The day has unravelled much faster than expected.',
      'A manageable problem has turned into a complete mess.',
      'Everything has decided to go wrong at once.',
      'I cannot believe this is the update I’m sending.',
    ]);

    final reason = detail == null
        ? scenario.dramaticReason
        : '${scenario.dramaticReason} $detail';
    final escalation = safeMode
        ? scenario.impact
        : scenario.dramaticImpact;

    return switch (length) {
      ExcuseLength.short => '$opening $reason ${scenario.shortClosing}',
      ExcuseLength.standard =>
        '$opening $reason $escalation ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$opening $reason $escalation ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _honestMessage(
    String situation,
    _Scenario scenario,
    String? detail,
    ExcuseLength length,
  ) {
    final opening = _nextText('honest-opening', const [
      'I’m going to be completely honest.',
      'Rather than invent a story, here is the truth.',
      'I owe you a straightforward answer.',
      'There is no dramatic emergency.',
      'I’m not going to dress this up.',
    ]);

    final detailSentence = detail == null ? '' : ' $detail';

    return switch (length) {
      ExcuseLength.short =>
        '$opening ${scenario.honestReason}$detailSentence ${scenario.honestClosing}',
      ExcuseLength.standard =>
        '$opening ${scenario.honestReason}$detailSentence ${scenario.honestImpact} ${scenario.honestClosing}',
      ExcuseLength.detailed =>
        '$opening ${scenario.honestReason}$detailSentence ${scenario.honestImpact} ${scenario.reassurance} ${scenario.honestClosing}',
    };
  }

  String _ridiculousMessage(
    String situation,
    _Scenario scenario,
    String? detail,
    ExcuseLength length,
    bool safeMode,
  ) {
    final opening = _nextText('ridiculous-opening', const [
      'This sounds invented, but reality has abandoned quality control.',
      'The universe has become unnecessarily involved in my schedule.',
      'I appear to be trapped in a low-budget disaster film.',
      'Against every law of probability, today has become absurd.',
      'Common sense is no longer in charge.',
    ]);

    final reason = detail == null
        ? scenario.ridiculousReason
        : '${scenario.ridiculousReason} $detail';
    final consequence = safeMode
        ? scenario.dramaticImpact
        : scenario.ridiculousImpact;

    return switch (length) {
      ExcuseLength.short => '$opening $reason ${scenario.shortClosing}',
      ExcuseLength.standard =>
        '$opening $reason $consequence ${scenario.standardClosing}',
      ExcuseLength.detailed =>
        '$opening $reason $consequence ${scenario.reassurance} ${scenario.standardClosing}',
    };
  }

  String _detailPhrase({
    required String detail,
    required String situation,
    required _Scenario scenario,
  }) {
    final kind = _classifyDetail(detail);
    final subject = _normaliseDetail(detail, kind);

    return switch (kind) {
      _DetailKind.personOrGroup =>
        'I also need to stay available because of something involving $subject.',
      _DetailKind.place =>
        'A related issue at $subject means I cannot leave this unresolved.',
      _DetailKind.object =>
        'Part of the problem involves $subject, which needs my attention today.',
      _DetailKind.event =>
        'The timing of $subject has also changed unexpectedly.',
      _DetailKind.subject =>
        'There is also a related complication involving $subject.',
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
    if (kind != _DetailKind.personOrGroup) return detail;

    final lower = detail.toLowerCase();
    final shouldTitleCase = _looksLikeName(detail) ||
        RegExp(r'\b(women|united|city|fc|team)\b').hasMatch(lower);
    if (!shouldTitleCase) return detail;

    return detail
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
    return words.every((word) => RegExp(r"^[A-Z][A-Za-z'-]*$").hasMatch(word));
  }

  _Score _score({
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
    required _Scenario scenario,
  }) {
    var believability = switch (tone) {
      'Believable' => scenario.baseBelievability,
      'Dramatic' => scenario.baseBelievability - 18,
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
        believability -= 3;
        riskPoints += 1;
    }

    if (detail.isNotEmpty) {
      final words = detail.split(' ').length;
      if (words <= 4) believability += 1;
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
        believableReason: 'A repair issue at home needs someone here until it is resolved.',
        dramaticReason: 'A repair issue at home has escalated and now needs constant attention.',
        honestReason: 'I am too depleted to do useful work today.',
        ridiculousReason: 'My home has become an unofficial command centre for a problem nobody understands.',
        impact: 'I cannot work reliably while I am dealing with it.',
        dramaticImpact: 'Every attempt to fix it has introduced another problem.',
        ridiculousImpact: 'I have apparently been promoted to emergency facilities manager without my consent.',
        reassurance: 'I will catch up on anything urgent as soon as I am able.',
        shortClosing: 'I need to step away today.',
        standardClosing: 'I will send an update when the situation is clearer.',
        honestImpact: 'Pretending otherwise would only create poor work and more problems later.',
        honestClosing: 'I will take responsibility for catching up properly.',
        baseBelievability: 88,
      ),
      _Scenario(
        believableReason: 'My transport has failed and I do not have a reliable alternative.',
        dramaticReason: 'My entire journey has collapsed with no workable alternative.',
        honestReason: 'I have not organised myself well enough to get there on time.',
        ridiculousReason: 'My journey has been defeated by transport, timing and one extremely confident pigeon.',
        impact: 'There is no realistic way for me to arrive when expected.',
        dramaticImpact: 'Every replacement option has failed almost immediately.',
        ridiculousImpact: 'Public transport and basic probability have both declined to cooperate.',
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
        believableReason: 'Something time-sensitive has come up at home.',
        dramaticReason: 'A problem at home has grown far beyond what I expected.',
        honestReason: 'I do not have the energy to socialise properly tonight.',
        ridiculousReason: 'My evening has been claimed by a household crisis with no respect for my plans.',
        impact: 'I need to stay here until it is dealt with.',
        dramaticImpact: 'Leaving now would make the situation considerably worse.',
        ridiculousImpact: 'I am apparently the only available adult with access to the correct key.',
        reassurance: 'I would rather rearrange than keep you waiting.',
        shortClosing: 'Can we move this to another day?',
        standardClosing: 'I am sorry for cancelling so late.',
        honestImpact: 'Forcing myself through the evening would not be fair to either of us.',
        honestClosing: 'I would rather rearrange and be properly present.',
        baseBelievability: 86,
      ),
    ],
    'Family': [
      _Scenario(
        believableReason: 'I need a quiet evening to deal with something personal.',
        dramaticReason: 'A personal situation has become emotionally overwhelming today.',
        honestReason: 'I need time alone and should have said that sooner.',
        ridiculousReason: 'My emotional battery has reached a percentage normally reserved for emergency warnings.',
        impact: 'I am not in the right state to be good company.',
        dramaticImpact: 'Trying to continue as normal would only make everything harder.',
        ridiculousImpact: 'Any further social interaction may cause the system to shut down completely.',
        reassurance: 'I will check in properly once I have had some space.',
        shortClosing: 'I need to stay home tonight.',
        standardClosing: 'Thank you for understanding.',
        honestImpact: 'I would rather say no clearly than turn up resentful or distracted.',
        honestClosing: 'I hope we can rearrange soon.',
        baseBelievability: 84,
      ),
    ],
    'Dating': [
      _Scenario(
        believableReason: 'I am not feeling well enough to be good company tonight.',
        dramaticReason: 'I have gone from slightly unwell to completely unable to face the evening.',
        honestReason: 'I am not in the right frame of mind for a date tonight.',
        ridiculousReason: 'My body has filed a formal objection to leaving the house.',
        impact: 'I would not be fully present if we met.',
        dramaticImpact: 'Trying to push through would make the evening worse for both of us.',
        ridiculousImpact: 'Even my shoes appear to have withdrawn their support.',
        reassurance: 'I would rather choose another night when I can enjoy it properly.',
        shortClosing: 'Can we reschedule?',
        standardClosing: 'I am sorry for the late change.',
        honestImpact: 'That is about my capacity today, not a lack of interest.',
        honestClosing: 'I would still like to arrange another time.',
        baseBelievability: 82,
      ),
    ],
    'School': [
      _Scenario(
        believableReason: 'I am not well enough to concentrate properly today.',
        dramaticReason: 'I have become much more unwell overnight and cannot focus safely.',
        honestReason: 'I have not prepared properly and need to be honest about that.',
        ridiculousReason: 'My preparation has disappeared into the same dimension as missing pens and completed homework.',
        impact: 'Attending would not result in useful work.',
        dramaticImpact: 'Trying to continue would leave me further behind rather than helping.',
        ridiculousImpact: 'My notes and my attention span have both left without forwarding addresses.',
        reassurance: 'I will review the missed material and catch up as soon as possible.',
        shortClosing: 'I will not be able to attend today.',
        standardClosing: 'Please send over anything important that I miss.',
        honestImpact: 'That is my responsibility, and I need to correct it directly.',
        honestClosing: 'I will take responsibility for catching up properly.',
        baseBelievability: 87,
      ),
    ],
    'Appointments': [
      _Scenario(
        believableReason: 'An urgent commitment now clashes with the appointment.',
        dramaticReason: 'An urgent commitment has moved without warning and taken over the time completely.',
        honestReason: 'I have double-booked myself and only just noticed.',
        ridiculousReason: 'My calendar has apparently developed free will and scheduled two realities at once.',
        impact: 'I cannot attend at the original time.',
        dramaticImpact: 'There is no practical way to resolve both commitments today.',
        ridiculousImpact: 'Unless I discover time travel before the appointment, one booking has to move.',
        reassurance: 'I would like to rearrange rather than leave the slot unused.',
        shortClosing: 'Can we reschedule?',
        standardClosing: 'I apologise for the inconvenience.',
        honestImpact: 'This is my scheduling mistake, not a problem with the appointment.',
        honestClosing: 'I will make sure the replacement time is properly protected.',
        baseBelievability: 89,
      ),
    ],
    'Gym': [
      _Scenario(
        believableReason: 'I am feeling too run down to train safely today.',
        dramaticReason: 'My energy has disappeared and training now feels actively unwise.',
        honestReason: 'I do not want to train today and need the rest more.',
        ridiculousReason: 'My motivation has left the building and taken my coordination with it.',
        impact: 'Pushing through would probably set me back rather than help.',
        dramaticImpact: 'Even a light session would be more punishment than progress.',
        ridiculousImpact: 'The dumbbells have won without needing to leave the rack.',
        reassurance: 'I will return when I can train properly rather than force it.',
        shortClosing: 'I am skipping today’s session.',
        standardClosing: 'I will rearrange the session.',
        honestImpact: 'I would rather admit that than invent a medical emergency.',
        honestClosing: 'I will get back to the routine next time.',
        baseBelievability: 85,
      ),
    ],
    'Neighbours': [
      _Scenario(
        believableReason: 'A problem at home needs my attention before it affects anyone else.',
        dramaticReason: 'A household problem is beginning to affect the surrounding property.',
        honestReason: 'I have delayed dealing with a problem that should have been handled sooner.',
        ridiculousReason: 'My property has started behaving like it wants its own neighbourhood meeting.',
        impact: 'I need to stay here until I know it is contained.',
        dramaticImpact: 'Ignoring it now could create a much larger issue for everyone nearby.',
        ridiculousImpact: 'The group chat is already approaching emergency broadcast status.',
        reassurance: 'I will keep everyone updated once I know more.',
        shortClosing: 'I need to deal with it immediately.',
        standardClosing: 'I am sorry for the disruption.',
        honestImpact: 'That delay is my responsibility, and I need to correct it now.',
        honestClosing: 'I will update you when it has been resolved.',
        baseBelievability: 86,
      ),
    ],
    'Deliveries': [
      _Scenario(
        believableReason: 'An essential delivery has been moved into a fixed time window.',
        dramaticReason: 'An essential delivery has been moved repeatedly and now requires me to stay available all day.',
        honestReason: 'I did not plan the delivery properly and now need to remain available for it.',
        ridiculousReason: 'A parcel has taken control of my schedule without providing any useful tracking information.',
        impact: 'There is nobody else available to receive it.',
        dramaticImpact: 'Missing it would restart the entire process and create another delay.',
        ridiculousImpact: 'The tracking page has offered three times, two locations and no truth.',
        reassurance: 'I will rearrange everything else around the confirmed window.',
        shortClosing: 'I need to stay in for it.',
        standardClosing: 'I am sorry for the inconvenience.',
        honestImpact: 'That is a planning mistake on my part.',
        honestClosing: 'I will organise the next delivery more carefully.',
        baseBelievability: 88,
      ),
    ],
  };
}

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

enum _DetailKind { personOrGroup, place, object, event, subject }

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
      final index = random.nextInt(_remaining.length - 1);
      final temporary = _remaining[index];
      _remaining[index] = _remaining.last;
      _remaining[_remaining.length - 1] = temporary;
    }
  }
}
