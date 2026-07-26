import 'dart:math';

import '../models/excuse_length.dart';
import '../models/generated_excuse.dart';

class ExcuseGenerator {
  ExcuseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, _ShuffleBag<String>> _bags = {};
  final List<String> _recentExcuses = [];

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
    final validSituation = situations.contains(situation) ? situation : 'Plans';
    final validTone = tones.contains(tone) ? tone : 'Believable';
    final profile = _profiles[validSituation]!;
    final cleanDetail = _cleanDetail(detail);

    var text = _buildMessage(
      profile: profile,
      situation: validSituation,
      tone: validTone,
      length: length,
      detail: cleanDetail,
      safeMode: safeMode,
    );

    for (var attempt = 0;
        attempt < 4 && _recentExcuses.contains(text);
        attempt++) {
      text = _buildMessage(
        profile: profile,
        situation: validSituation,
        tone: validTone,
        length: length,
        detail: cleanDetail,
        safeMode: safeMode,
      );
    }

    _recentExcuses.insert(0, text);
    if (_recentExcuses.length > 80) _recentExcuses.removeLast();

    final score = _score(
      situation: validSituation,
      tone: validTone,
      length: length,
      detail: cleanDetail,
      safeMode: safeMode,
    );

    return GeneratedExcuse(
      text: text,
      situation: validSituation,
      tone: validTone,
      believability: score.believability,
      followUpRisk: score.risk,
    );
  }

  String _buildMessage({
    required _SituationProfile profile,
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
  }) {
    final opening = _next('opening:$tone:$length', _openings[tone]!);
    final reason = _next('reason:$situation:$tone', profile.reasonsFor(tone));
    final detailSentence = detail.isEmpty
        ? ''
        : _detailSentence(
            detail: detail,
            tone: tone,
            situation: situation,
            safeMode: safeMode,
          );
    final impact = _next('impact:$situation:$tone', profile.impactsFor(tone));
    final closing = _next('closing:$situation:$tone', profile.closingsFor(tone));

    final parts = switch (length) {
      ExcuseLength.short => [opening, reason, detailSentence, closing],
      ExcuseLength.standard => [opening, reason, detailSentence, impact, closing],
      ExcuseLength.detailed => [
          opening,
          reason,
          detailSentence,
          impact,
          _next('reassurance:$situation', profile.reassurances),
          closing,
        ],
    };

    return _clean(parts.where((part) => part.isNotEmpty).join(' '));
  }

  String _detailSentence({
    required String detail,
    required String tone,
    required String situation,
    required bool safeMode,
  }) {
    final kind = _classifyDetail(detail);
    final subject = _normaliseDetail(detail, kind);
    final templates = _detailTemplates[tone]![kind]!;
    var sentence = _next('detail:$tone:${kind.name}', templates)
        .replaceAll('{detail}', subject);

    if (safeMode && tone == 'Dramatic') {
      sentence = _next('detail:safe:dramatic:${kind.name}', _safeDramaticDetails[kind]!)
          .replaceAll('{detail}', subject);
    }

    if (situation == 'Work' && sentence.startsWith('I need to prioritise')) {
      sentence = sentence.replaceFirst(
        'I need to prioritise',
        'I need to deal with',
      );
    }

    return sentence;
  }

  _Score _score({
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
  }) {
    var believability = switch (tone) {
      'Believable' => 88,
      'Dramatic' => 66,
      'Brutally honest' => 94,
      'Ridiculous' => 24,
      _ => 75,
    };

    var riskPoints = switch (tone) {
      'Believable' => 1,
      'Dramatic' => 4,
      'Brutally honest' => 2,
      'Ridiculous' => 6,
      _ => 3,
    };

    believability += switch (situation) {
      'Work' || 'School' || 'Appointments' => 2,
      'Dating' => -2,
      'Neighbours' => -1,
      _ => 0,
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
      final wordCount = detail.split(' ').length;
      if (wordCount <= 4) {
        believability += 1;
      } else if (wordCount > 10) {
        believability -= 7;
        riskPoints += 2;
      }

      if (_looksUnusual(detail)) {
        believability -= tone == 'Ridiculous' ? 0 : 6;
        riskPoints += 1;
      }
    }

    if (safeMode) {
      believability += tone == 'Ridiculous' ? 1 : 3;
      riskPoints -= 1;
    }

    believability += _random.nextInt(7) - 3;
    final clamped = believability.clamp(1, 99);
    final risk = switch (riskPoints.clamp(0, 8)) {
      <= 2 => FollowUpRisk.low,
      <= 4 => FollowUpRisk.medium,
      _ => FollowUpRisk.high,
    };

    return _Score(clamped, risk);
  }

  _DetailKind _classifyDetail(String detail) {
    final lower = detail.toLowerCase();
    if (RegExp(r'\b(meeting|appointment|match|game|concert|event|delivery|shift|training|lesson|interview|visit)\b')
        .hasMatch(lower)) {
      return _DetailKind.event;
    }
    if (RegExp(r'\b(home|house|office|school|hospital|station|airport|garage|venue|london|town|city)\b')
        .hasMatch(lower)) {
      return _DetailKind.place;
    }
    if (RegExp(r'^(my|the|a|an)\s+').hasMatch(lower) ||
        RegExp(r'\b(car|boiler|phone|laptop|pet|dog|cat|parcel|key|keys|internet)\b')
            .hasMatch(lower)) {
      return _DetailKind.object;
    }
    if (_looksLikeProperName(detail) ||
        RegExp(r'\b(mum|mom|dad|brother|sister|friend|manager|teacher|doctor|team)\b')
            .hasMatch(lower)) {
      return _DetailKind.personOrGroup;
    }
    return _DetailKind.subject;
  }

  String _normaliseDetail(String detail, _DetailKind kind) {
    if (kind == _DetailKind.personOrGroup && _looksLikeProperName(detail)) {
      return detail
          .split(' ')
          .map((word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
    }
    return detail;
  }

  bool _looksLikeProperName(String detail) {
    final words = detail.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty || words.length > 5) return false;
    return words.every(
      (word) => RegExp(r'^[A-Z][A-Za-z\'-]*$').hasMatch(word) ||
          const {'FC', 'Women', 'United', 'City'}.contains(word),
    );
  }

  bool _looksUnusual(String detail) {
    return RegExp(
      r'\b(alien|dragon|zombie|pigeon|spaceship|pirate|ghost|unicorn|volcano|royal family|secret agent)\b',
      caseSensitive: false,
    ).hasMatch(detail);
  }

  String _cleanDetail(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?,;:]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  String _next(String key, List<String> source) {
    return (_bags[key] ??= _ShuffleBag(source, _random)).next();
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(' .', '.')
      .replaceAll('..', '.')
      .trim();

  static const Map<String, List<String>> _openings = {
    'Believable': [
      'I’m sorry for the short notice.',
      'I was hoping I could still make this work.',
      'I’ve tried to avoid changing the plan.',
      'I wanted to let you know as early as I could.',
      'Unfortunately, something has changed today.',
      'I need to be realistic about today.',
      'I’ve only just had confirmation of a problem.',
      'I hate having to rearrange at the last minute.',
      'This is awkward timing, and I’m sorry.',
      'I genuinely expected to be available.',
    ],
    'Dramatic': [
      'I wish I were exaggerating.',
      'The day has unravelled much faster than expected.',
      'A small problem has turned into a complete mess.',
      'I’ve been blindsided by a situation that keeps escalating.',
      'Everything has decided to go wrong at once.',
      'I cannot believe this is the update I’m sending.',
      'The situation has moved firmly into damage-control territory.',
      'Today has taken a fairly disastrous turn.',
      'What looked manageable an hour ago is no longer manageable.',
      'I’m currently dealing with considerably more chaos than planned.',
    ],
    'Brutally honest': [
      'I’m going to be completely honest.',
      'Rather than invent an elaborate story, here is the truth.',
      'I owe you a straightforward answer.',
      'There is no dramatic emergency.',
      'I’m not going to dress this up.',
      'The honest version is simple.',
      'I should have said this sooner.',
      'I would rather be direct than make something up.',
      'No complicated excuse here.',
      'The plain truth is this.',
    ],
    'Ridiculous': [
      'This sounds invented, but reality has abandoned quality control.',
      'In a development nobody could reasonably have predicted, things have gone sideways.',
      'The universe has become unnecessarily involved in my schedule.',
      'I appear to be trapped in a very low-budget disaster film.',
      'Against every law of probability, today has become absurd.',
      'Please understand that common sense is no longer in charge.',
      'An unreasonable chain of events has taken control of the day.',
      'I would not believe this explanation either, but here we are.',
      'Reality has produced a problem with far too many moving parts.',
      'For reasons no responsible adult can explain, normal plans have collapsed.',
    ],
  };

  static const Map<_DetailKind, List<String>> _safeDramaticDetails = {
    _DetailKind.personOrGroup: [
      'A complication involving {detail} has added another urgent moving part.',
      'I also need to stay available because of something involving {detail}.',
    ],
    _DetailKind.place: [
      'A separate issue connected to {detail} has made the timing even tighter.',
      'I now also need to deal with something at {detail}.',
    ],
    _DetailKind.object: [
      'The problem also involves {detail}, which I cannot safely leave unresolved.',
      'I am also waiting on a resolution involving {detail}.',
    ],
    _DetailKind.event: [
      'A change involving {detail} has added another fixed commitment.',
      'The timing of {detail} has also shifted unexpectedly.',
    ],
    _DetailKind.subject: [
      'There is an additional issue involving {detail} that needs attention.',
      'Something connected to {detail} has made the situation more complicated.',
    ],
  };

  static const Map<String, Map<_DetailKind, List<String>>> _detailTemplates = {
    'Believable': {
      _DetailKind.personOrGroup: [
        'I also need to help {detail} with something that cannot be moved.',
        'Part of the problem involves {detail}, and I need to stay available.',
        'I have also been asked to deal with something involving {detail}.',
      ],
      _DetailKind.place: [
        'I also need to deal with an issue at {detail}.',
        'Part of this requires me to remain at {detail}.',
        'There is also a time-sensitive problem connected to {detail}.',
      ],
      _DetailKind.object: [
        'The situation also involves {detail}, which I cannot leave unresolved.',
        'I am waiting for help with {detail}, and the timing is uncertain.',
        'A problem with {detail} has made the original plan unworkable.',
      ],
      _DetailKind.event: [
        'The timing of {detail} has changed unexpectedly.',
        'I now have a fixed commitment involving {detail}.',
        'A last-minute change to {detail} has created the clash.',
      ],
      _DetailKind.subject: [
        'There is also something involving {detail} that needs my attention.',
        'An issue connected to {detail} has added an unavoidable complication.',
        'I also need to resolve something related to {detail}.',
      ],
    },
    'Dramatic': {
      _DetailKind.personOrGroup: [
        'To make matters worse, {detail} is now caught up in the situation as well.',
        'The latest twist is that I also need to coordinate something involving {detail}.',
        'As if that were not enough, {detail} has become another urgent part of this.',
      ],
      _DetailKind.place: [
        'The situation has now expanded to include a problem at {detail}.',
        'I am also being pulled into an issue connected to {detail}.',
        'The latest complication is unfolding at {detail}.',
      ],
      _DetailKind.object: [
        'The situation now also depends on resolving a problem with {detail}.',
        'Every attempt to sort out {detail} has introduced another delay.',
        'As if the day needed another problem, {detail} has now failed me too.',
      ],
      _DetailKind.event: [
        'The timing of {detail} has shifted and thrown the rest of the day into chaos.',
        'A sudden change involving {detail} has made the clash unavoidable.',
        'The latest escalation is an unexpected change to {detail}.',
      ],
      _DetailKind.subject: [
        'To make matters worse, the situation now also involves {detail}.',
        'The latest complication is something connected to {detail}.',
        'An additional problem involving {detail} has pushed this over the edge.',
      ],
    },
    'Brutally honest': {
      _DetailKind.personOrGroup: [
        'I have chosen to prioritise something involving {detail}.',
        'I need to give my attention to {detail} instead.',
        'The specific commitment I am prioritising involves {detail}.',
      ],
      _DetailKind.place: [
        'I need to spend that time at {detail} instead.',
        'The practical reason is that I need to be at {detail}.',
        'I have decided that dealing with something at {detail} comes first today.',
      ],
      _DetailKind.object: [
        'I need to sort out {detail} instead of forcing the original plan.',
        'The practical issue I am prioritising is {detail}.',
        'I would rather deal with {detail} properly than pretend I can do both.',
      ],
      _DetailKind.event: [
        'I have decided to prioritise {detail}.',
        'The clash is with {detail}, and I am choosing that commitment.',
        'I cannot realistically fit this around {detail}.',
      ],
      _DetailKind.subject: [
        'The extra context is that I need to prioritise {detail}.',
        'I have chosen to give my attention to {detail} instead.',
        'The specific thing taking priority today is {detail}.',
      ],
    },
    'Ridiculous': {
      _DetailKind.personOrGroup: [
        'Somehow, {detail} has now become involved, which raises several new questions.',
        'For reasons lost to history, I am now coordinating something involving {detail}.',
        '{detail} has entered the story, and the plot has deteriorated accordingly.',
      ],
      _DetailKind.place: [
        'The chaos has now spread to {detail}, apparently without planning permission.',
        'I am being redirected to {detail}, where logic is reportedly unavailable.',
        'The next stage of this nonsense is taking place at {detail}.',
      ],
      _DetailKind.object: [
        '{detail} has become the central character in a crisis it did not audition for.',
        'The entire operation now depends on {detail}, which feels deeply unwise.',
        'I have been defeated by {detail} in circumstances too embarrassing to document.',
      ],
      _DetailKind.event: [
        '{detail} has been rescheduled by forces that clearly oppose me personally.',
        'The timing of {detail} has collapsed into complete administrative nonsense.',
        '{detail} is now the anchor point of an operation nobody appears qualified to run.',
      ],
      _DetailKind.subject: [
        'Somehow, {detail} is now involved, which raises more questions than it answers.',
        '{detail} has become central to events despite having no obvious reason to be here.',
        'The situation now includes {detail}, because apparently it was not strange enough.',
      ],
    },
  };

  static const Map<String, _SituationProfile> _profiles = {
    'Work': _SituationProfile(
      believableReasons: [
        'A problem at home needs someone here until it is resolved.',
        'My transport has failed and I do not have a reliable alternative.',
        'A family responsibility has changed at very short notice.',
        'I am dealing with a health issue that makes working properly unrealistic.',
        'An urgent appointment has been moved into the working day.',
        'I am waiting for an essential repair with no reliable arrival window.',
      ],
      honestReasons: [
        'I am too depleted to do useful work today.',
        'I have overcommitted and need to reduce the load.',
        'I need a day away rather than pretending I can work effectively.',
        'I am not in the right state to give the work proper attention.',
      ],
      ridiculousReasons: [
        'My home has become an unofficial command centre for a problem nobody understands.',
        'A household malfunction has promoted me to emergency facilities manager.',
        'My journey has been defeated by transport, weather and one extremely confident pigeon.',
        'I have been assigned to a crisis meeting by people who have never met me.',
      ],
      believableImpacts: [
        'I cannot give the day the focus or reliability it needs.',
        'That leaves me unable to arrive or log on at a dependable time.',
        'I need to remain available until I know what happens next.',
      ],
      dramaticImpacts: [
        'Every update has introduced another moving part, so the day is no longer recoverable.',
        'I am now coordinating several things at once and cannot step away responsibly.',
        'What began as a minor disruption has consumed the entire working day.',
      ],
      honestImpacts: [
        'Turning up distracted would be less useful than being honest now.',
        'I would rather reset properly than produce poor work and excuses all day.',
      ],
      ridiculousImpacts: [
        'Normal productivity has been suspended pending the return of common sense.',
        'I am apparently the only available person with a phone charger and basic literacy.',
      ],
      believableClosings: [
        'I will send an update as soon as the position is clearer.',
        'Please send anything urgent and I will respond when I can.',
        'I am sorry for the disruption and will make sure nothing important is left hanging.',
      ],
      honestClosings: [
        'I understand the inconvenience and will pick things up properly when I return.',
        'I should have communicated this earlier, and I am sorry.',
      ],
      ridiculousClosings: [
        'I will report back if the operation ends without a committee being formed.',
        'I hope to return once somebody locates the adult in charge.',
      ],
      reassurances: [
        'I will keep an eye on anything genuinely time-sensitive.',
        'I have not made this decision lightly.',
        'I will make sure the next steps are clear rather than leaving anyone guessing.',
      ],
    ),
    'Plans': _SituationProfile(
      believableReasons: [
        'Something time-sensitive has come up at home.',
        'A family commitment has shifted and now clashes completely.',
        'My transport arrangements have fallen through.',
        'I am feeling unwell enough that going out would be a bad idea.',
        'My workday has overrun far beyond what I expected.',
        'I need to stay available for an urgent practical issue.',
      ],
      honestReasons: [
        'I do not have the energy to socialise properly tonight.',
        'I have overbooked myself and need to cancel something.',
        'I need a quiet evening more than I need another commitment.',
        'I am not in the mood to go out and do not want to fake it.',
      ],
      ridiculousReasons: [
        'My evening has been requisitioned by a chain of events involving no competent adults.',
        'A simple household task has escalated into a neighbourhood-level incident.',
        'My transport plan has collapsed in a manner normally reserved for documentaries.',
        'I am trapped in an administrative loop with no visible exit.',
      ],
      believableImpacts: [
        'I cannot get there at a sensible time or be good company when I arrive.',
        'I would rather rearrange than keep you waiting for an uncertain update.',
        'The evening is no longer workable without rushing everything.',
      ],
      dramaticImpacts: [
        'The situation is still changing, and every estimate I give becomes wrong immediately.',
        'There is no realistic way to rescue the evening without creating another problem.',
        'The entire plan has been swallowed by events outside my control.',
      ],
      honestImpacts: [
        'Forcing myself through it would make the evening worse for both of us.',
        'I would rather disappoint you briefly than turn up resentful and distracted.',
      ],
      ridiculousImpacts: [
        'My free time is currently being held hostage by events too strange to summarise.',
        'The evening has exceeded its permitted number of complications.',
      ],
      believableClosings: [
        'Can we choose another day when I can actually be present?',
        'I am sorry for the late change and will make it up to you.',
        'Thank you for understanding; I will suggest another time soon.',
      ],
      honestClosings: [
        'I know this is inconvenient, but rearranging is the better option.',
        'I will suggest another time instead of leaving this vague.',
      ],
      ridiculousClosings: [
        'I will reschedule once the universe stops editing my calendar.',
        'I owe you a replacement plan with substantially fewer plot twists.',
      ],
      reassurances: [
        'I still want to see you; today is simply the wrong day.',
        'I would rather give you a clear answer now than cancel even later.',
        'This is about the timing, not the plan itself.',
      ],
    ),
    'Family': _SituationProfile(
      believableReasons: [
        'I need some quiet time to deal with a personal issue.',
        'A last-minute responsibility has landed with me.',
        'I am feeling run down and need to stay home.',
        'I have taken on more than I can realistically manage today.',
        'Something private needs my attention before I make other plans.',
      ],
      honestReasons: [
        'I need space tonight and do not want to explain every detail.',
        'I am stretched too thin and need to protect my energy.',
        'I do not have the capacity for another family commitment today.',
        'I need to say no instead of agreeing out of guilt.',
      ],
      ridiculousReasons: [
        'A minor family request has evolved into a committee, a spreadsheet and several conflicting instructions.',
        'I have been appointed coordinator of a crisis nobody will define clearly.',
        'The family group chat has become operationally significant.',
      ],
      believableImpacts: [
        'I would not be able to give the time or attention this deserves.',
        'I need to keep the rest of the day simple.',
        'Trying to fit everything in would leave me distracted and rushed.',
      ],
      dramaticImpacts: [
        'The situation has become emotionally and practically exhausting.',
        'I need to step away before one more request turns this into a full-scale operation.',
      ],
      honestImpacts: [
        'I would rather set a clear boundary than turn up frustrated.',
        'Saying yes when I mean no would not be fair to anyone.',
      ],
      ridiculousImpacts: [
        'I am apparently now responsible for minutes, transport and emotional diplomacy.',
        'Nobody knows the plan, but everyone has strong objections to it.',
      ],
      believableClosings: [
        'I hope you understand that I need to take this time for myself.',
        'I will check in properly once I have dealt with everything.',
        'Thank you for giving me a little breathing room.',
      ],
      honestClosings: [
        'I care about you, but I still need to set this boundary.',
        'I will reach out when I have the headspace to do it properly.',
      ],
      ridiculousClosings: [
        'I will return once the group chat has lost quorum.',
        'I hope to be released after the next unnecessary vote.',
      ],
      reassurances: [
        'This is not personal; I simply need less on my plate today.',
        'I would rather be clear than become distant or irritable.',
        'I am not disappearing, just reducing what I can manage today.',
      ],
    ),
    'Dating': _SituationProfile(
      believableReasons: [
        'I am not feeling well enough to be good company tonight.',
        'A personal issue has come up and I need to stay available.',
        'My day has overrun and I am completely drained.',
        'My transport arrangements have fallen apart.',
        'I need to deal with something before I can properly switch off.',
      ],
      honestReasons: [
        'I am not feeling the date tonight and do not want to fake enthusiasm.',
        'I need to slow this down rather than force another plan.',
        'I am too drained to be present or enjoyable company.',
        'I need some space before arranging another date.',
      ],
      ridiculousReasons: [
        'My evening has been intercepted by a domestic incident with suspiciously romantic timing.',
        'A sequence of events has made me less available than a fictional spy.',
        'My transport has entered a committed relationship with unreliability.',
      ],
      believableImpacts: [
        'I would rather rearrange than give you a rushed or distracted evening.',
        'I cannot arrive in the frame of mind I would want for a date.',
        'The timing would make the whole evening feel forced.',
      ],
      dramaticImpacts: [
        'The evening has become impossible to rescue without pretending everything is fine.',
        'I am one more complication away from becoming terrible company.',
      ],
      honestImpacts: [
        'Turning up half-hearted would be unfair to both of us.',
        'Being clear now is kinder than going through the motions.',
      ],
      ridiculousImpacts: [
        'Romance has been postponed by events with no respect for narrative structure.',
        'I would arrive with the energy of a hostage reading a prepared statement.',
      ],
      believableClosings: [
        'Can we reschedule for a time when I can be fully present?',
        'I am sorry for the late change and hope we can choose another night.',
        'I did not want to disappear or leave you waiting.',
      ],
      honestClosings: [
        'I understand if that is disappointing, but honesty is better here.',
        'I will reach out when I can suggest something I genuinely want to commit to.',
      ],
      ridiculousClosings: [
        'I hope we can retry when my life returns to a less experimental genre.',
        'I owe you a date with fewer emergency briefings.',
      ],
      reassurances: [
        'I wanted to tell you directly rather than become vague or disappear.',
        'This is not an invitation to wait around for an uncertain update.',
        'A clear change of plan is better than a poor evening for both of us.',
      ],
    ),
    'School': _SituationProfile(
      believableReasons: [
        'I have been unwell and am not fit to concentrate properly.',
        'A medical appointment has been moved unexpectedly.',
        'A family issue needs my attention today.',
        'My transport has been cancelled with no workable alternative.',
        'A problem at home means I cannot leave yet.',
      ],
      honestReasons: [
        'I am overwhelmed and need a day to reset before I fall further behind.',
        'I have not prepared properly and need to be honest about that.',
        'I am not in a condition to learn effectively today.',
      ],
      ridiculousReasons: [
        'My route to school has been defeated by transport, timing and improbable local wildlife.',
        'A simple morning problem has developed into an educational field trip in crisis management.',
        'My timetable has been overruled by events with no respect for attendance policy.',
      ],
      believableImpacts: [
        'I would not be able to participate or focus usefully.',
        'That makes attendance unrealistic today.',
        'I need to deal with this before I can return properly.',
      ],
      dramaticImpacts: [
        'The morning has become too unstable for me to give a reliable arrival time.',
        'Every attempt to leave has created another delay.',
      ],
      honestImpacts: [
        'Pretending otherwise would waste everyone’s time.',
        'I need to take responsibility and catch up properly afterwards.',
      ],
      ridiculousImpacts: [
        'Formal education has temporarily lost the scheduling dispute.',
        'I am learning a great deal, unfortunately none of it is on the curriculum.',
      ],
      believableClosings: [
        'Please let me know what I should complete from home.',
        'I will catch up on anything I miss as soon as possible.',
        'I will confirm when I expect to return.',
      ],
      honestClosings: [
        'I will take responsibility for catching up rather than making excuses later.',
        'Please send the work and I will deal with it directly.',
      ],
      ridiculousClosings: [
        'I will return once the practical exam in surviving the morning is complete.',
        'Please record this as absent due to excessive plot development.',
      ],
      reassurances: [
        'I will check the online materials and keep up where possible.',
        'I am not treating the missed work casually.',
        'I will provide any required information when I am able.',
      ],
    ),
    'Appointments': _SituationProfile(
      believableReasons: [
        'An earlier commitment has overrun and I cannot arrive on time.',
        'My transport has been delayed beyond the appointment window.',
        'I am unwell and need to rearrange rather than attend.',
        'A family responsibility now clashes with the booking.',
        'An urgent issue at home means I cannot leave.',
      ],
      honestReasons: [
        'I mismanaged the timing and cannot make the appointment.',
        'I am not prepared for the appointment and need to rearrange it.',
        'I have overbooked myself and this is the commitment I need to move.',
      ],
      ridiculousReasons: [
        'My calendar has created two appointments in one body and refuses to negotiate.',
        'The journey has become an obstacle course designed by local government.',
        'A routine booking has attracted an unreasonable number of side quests.',
      ],
      believableImpacts: [
        'I do not want to waste the appointment slot by arriving too late.',
        'There is no reliable way for me to reach you within the agreed window.',
        'Rearranging is now the most practical option.',
      ],
      dramaticImpacts: [
        'The timing has collapsed completely and there is no credible rescue plan.',
        'Every revised arrival estimate has already become obsolete.',
      ],
      honestImpacts: [
        'This is my scheduling mistake, and I need to correct it directly.',
        'Pretending I might still arrive would only waste more time.',
      ],
      ridiculousImpacts: [
        'Time itself appears to have rejected the booking.',
        'I am currently losing an argument with both a clock and a sat-nav.',
      ],
      believableClosings: [
        'Could we please arrange the next available time?',
        'I apologise for the disruption and would like to rebook.',
        'Please let me know what options are available for rearranging.',
      ],
      honestClosings: [
        'I apologise and understand if there is a cancellation policy.',
        'Please tell me the clearest way to correct this.',
      ],
      ridiculousClosings: [
        'I would like to rebook for a date on which time behaves normally.',
        'Please offer the next slot not currently opposed by fate.',
      ],
      reassurances: [
        'I am giving notice now rather than arriving late without explanation.',
        'I still need the appointment and intend to rearrange it promptly.',
        'I understand that this may inconvenience your schedule.',
      ],
    ),
    'Gym': _SituationProfile(
      believableReasons: [
        'I am feeling run down and training would not be sensible today.',
        'A work commitment has overrun into the session.',
        'My transport has fallen through.',
        'A family responsibility now clashes with the booking.',
        'I have picked up a minor strain and need to rest it.',
      ],
      honestReasons: [
        'I do not have the motivation to train today.',
        'I need rest more than I need to force a session.',
        'I have organised my day badly and the gym is what has to move.',
      ],
      ridiculousReasons: [
        'My fitness plan has been defeated by a chair, a snack and weak governance.',
        'I have sustained an administrative injury while trying to organise the session.',
        'The route to physical improvement has been blocked by deeply unathletic events.',
      ],
      believableImpacts: [
        'Training through it would be unproductive and could make things worse.',
        'I cannot arrive with enough time to complete the session properly.',
        'It makes more sense to rearrange than rush through it.',
      ],
      dramaticImpacts: [
        'My body and schedule have formed a surprisingly effective opposition coalition.',
        'The day has removed every realistic route to a useful session.',
      ],
      honestImpacts: [
        'Forcing it would only produce a poor session and more frustration.',
        'I need to accept that today is not happening and restart properly next time.',
      ],
      ridiculousImpacts: [
        'Athletic excellence has been postponed by an elite-level lack of coordination.',
        'The only reps happening today are repeated apologies.',
      ],
      believableClosings: [
        'Can we move the session to another day?',
        'I am sorry for the late change and will rebook promptly.',
        'I would rather return when I can train properly.',
      ],
      honestClosings: [
        'I will reschedule instead of pretending this was unavoidable.',
        'I need to take responsibility and get the next session booked.',
      ],
      ridiculousClosings: [
        'I will return when my calendar passes its fitness assessment.',
        'Please preserve my dignity and offer another slot.',
      ],
      reassurances: [
        'I am not abandoning the plan; I am moving one session.',
        'Resting or rearranging today is the more sensible choice.',
        'I will confirm a replacement rather than leaving this open-ended.',
      ],
    ),
    'Neighbours': _SituationProfile(
      believableReasons: [
        'I cannot help with this today because something urgent has come up.',
        'I need to deal with a problem inside my own home first.',
        'I am not available during the time you need me.',
        'A family commitment means I cannot take this on.',
        'I am unwell and need to keep the day quiet.',
      ],
      honestReasons: [
        'I do not have the capacity to take on another favour.',
        'I need to say no rather than agree and resent it.',
        'I am not comfortable getting involved in this.',
        'I want to keep a clearer boundary around neighbourly requests.',
      ],
      ridiculousReasons: [
        'The street has generated more administration than a small country.',
        'A simple neighbourly request has become a cross-boundary diplomatic incident.',
        'The local group chat has declared an emergency without defining it.',
      ],
      believableImpacts: [
        'I would not be able to help reliably or at the agreed time.',
        'Taking it on would leave both of us waiting on an uncertain answer.',
        'I need to keep my commitments limited today.',
      ],
      dramaticImpacts: [
        'The situation has already expanded beyond what I can reasonably absorb.',
        'One more moving part would turn an awkward day into a complete mess.',
      ],
      honestImpacts: [
        'A clear no is better than an unreliable yes.',
        'I would rather be direct than create an expectation I cannot meet.',
      ],
      ridiculousImpacts: [
        'The postcode has exceeded its daily allocation of complications.',
        'I am declining promotion to unpaid neighbourhood operations manager.',
      ],
      believableClosings: [
        'I am sorry I cannot help this time.',
        'I hope you are able to find another arrangement.',
        'Thank you for understanding that I need to decline.',
      ],
      honestClosings: [
        'I hope the direct answer is more useful than a vague excuse.',
        'I need to keep this boundary, even if it is awkward.',
      ],
      ridiculousClosings: [
        'I wish the street every success in appointing a replacement coordinator.',
        'Please remove my name from the emergency rota I never joined.',
      ],
      reassurances: [
        'This is about my availability, not a criticism of the request.',
        'I wanted to answer clearly rather than leave you waiting.',
        'I am not able to commit reliably, so declining is the fairer option.',
      ],
    ),
    'Deliveries': _SituationProfile(
      believableReasons: [
        'The delivery window has changed and nobody else can be here.',
        'The courier requires a signature and cannot offer a narrower time.',
        'An essential parcel has been moved into the middle of the day.',
        'The previous delivery attempt failed and this is the only replacement slot.',
        'I need to remain at the address until the courier arrives.',
      ],
      honestReasons: [
        'I chose a delivery window that clashes with the plan.',
        'I need the parcel enough that I am prioritising it today.',
        'I organised this badly and now need to stay home for the delivery.',
      ],
      ridiculousReasons: [
        'The courier has offered a delivery window spanning most of recorded history.',
        'My parcel is travelling through a logistics system powered mainly by mystery.',
        'I am waiting for a driver whose location appears to be classified information.',
      ],
      believableImpacts: [
        'I cannot leave without risking another failed attempt.',
        'The uncertain timing makes the original plan impossible to guarantee.',
        'I need to stay here until it has been completed.',
      ],
      dramaticImpacts: [
        'Every tracking update has made the arrival time less clear.',
        'The delivery has somehow consumed the entire day without physically arriving.',
      ],
      honestImpacts: [
        'This is a practical choice, not an emergency.',
        'I would rather admit the clash than invent something more impressive.',
      ],
      ridiculousImpacts: [
        'I have become a full-time observer of a map containing one motionless van.',
        'Leaving now would apparently reset the entire logistics timeline.',
      ],
      believableClosings: [
        'I am sorry for the inconvenience and will update you once it arrives.',
        'Can we rearrange for a time that does not depend on a courier window?',
        'Thank you for understanding the practical problem.',
      ],
      honestClosings: [
        'I understand that this is not a glamorous reason, but it is the real one.',
        'I will plan the replacement more carefully.',
      ],
      ridiculousClosings: [
        'I will be free when the parcel completes its heroic journey.',
        'I will update you if the van moves or civilisation ends first.',
      ],
      reassurances: [
        'I am giving notice now because the timing is unlikely to improve.',
        'The clash is temporary and specific to today.',
        'I will confirm a replacement plan once the delivery is complete.',
      ],
    ),
  };
}

class _SituationProfile {
  const _SituationProfile({
    required this.believableReasons,
    required this.honestReasons,
    required this.ridiculousReasons,
    required this.believableImpacts,
    required this.dramaticImpacts,
    required this.honestImpacts,
    required this.ridiculousImpacts,
    required this.believableClosings,
    required this.honestClosings,
    required this.ridiculousClosings,
    required this.reassurances,
  });

  final List<String> believableReasons;
  final List<String> honestReasons;
  final List<String> ridiculousReasons;
  final List<String> believableImpacts;
  final List<String> dramaticImpacts;
  final List<String> honestImpacts;
  final List<String> ridiculousImpacts;
  final List<String> believableClosings;
  final List<String> honestClosings;
  final List<String> ridiculousClosings;
  final List<String> reassurances;

  List<String> reasonsFor(String tone) => switch (tone) {
        'Brutally honest' => honestReasons,
        'Ridiculous' => ridiculousReasons,
        _ => believableReasons,
      };

  List<String> impactsFor(String tone) => switch (tone) {
        'Dramatic' => dramaticImpacts,
        'Brutally honest' => honestImpacts,
        'Ridiculous' => ridiculousImpacts,
        _ => believableImpacts,
      };

  List<String> closingsFor(String tone) => switch (tone) {
        'Brutally honest' => honestClosings,
        'Ridiculous' => ridiculousClosings,
        _ => believableClosings,
      };
}

class _Score {
  const _Score(this.believability, this.risk);

  final num believability;
  final FollowUpRisk risk;
}

enum _DetailKind { personOrGroup, place, object, event, subject }

class _ShuffleBag<T> {
  _ShuffleBag(List<T> source, this.random) : _source = List<T>.from(source) {
    _refill();
  }

  final List<T> _source;
  final Random random;
  final List<T> _remaining = [];
  T? _lastValue;

  T next() {
    if (_remaining.isEmpty) _refill();
    final value = _remaining.removeLast();
    _lastValue = value;
    return value;
  }

  void _refill() {
    _remaining
      ..clear()
      ..addAll(_source)
      ..shuffle(random);

    if (_lastValue != null &&
        _remaining.length > 1 &&
        _remaining.last == _lastValue) {
      final swapIndex = random.nextInt(_remaining.length - 1);
      final temporary = _remaining[swapIndex];
      _remaining[swapIndex] = _remaining.last;
      _remaining[_remaining.length - 1] = temporary;
    }
  }
}
