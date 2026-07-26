import 'dart:math';

import '../models/excuse_length.dart';
import '../models/generated_excuse.dart';

class ExcuseGenerator {
  ExcuseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, _ShuffleBag<String>> _bags = {};
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

    var text = _compose(
      situation: resolvedSituation,
      tone: resolvedTone,
      length: length,
      detail: cleanDetail,
      safeMode: safeMode,
    );

    for (var attempt = 0; attempt < 4 && _recent.contains(text); attempt++) {
      text = _compose(
        situation: resolvedSituation,
        tone: resolvedTone,
        length: length,
        detail: cleanDetail,
        safeMode: safeMode,
      );
    }

    _recent.insert(0, text);
    if (_recent.length > 80) _recent.removeLast();

    final score = _calculateScore(
      situation: resolvedSituation,
      tone: resolvedTone,
      length: length,
      detail: cleanDetail,
      safeMode: safeMode,
    );

    return GeneratedExcuse(
      text: text,
      situation: resolvedSituation,
      tone: resolvedTone,
      believability: score.believability,
      followUpRisk: score.risk,
    );
  }

  String _compose({
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
  }) {
    final reason = _next(
      'reason:$situation:$tone',
      _reasonsFor(situation, tone),
    );
    final detailSentence = detail.isEmpty
        ? ''
        : _detailSentence(detail, tone, safeMode);

    final sentences = <String>[
      _next('opening:$tone', _openings[tone]!),
      reason,
    ];

    if (detailSentence.isNotEmpty) sentences.add(detailSentence);

    if (length != ExcuseLength.short) {
      sentences.add(_next('impact:$situation:$tone', _impactsFor(situation, tone)));
    }

    if (length == ExcuseLength.detailed) {
      sentences.add(_next('reassurance:$situation', _reassurances[situation]!));
    }

    sentences.add(_next('closing:$situation:$tone', _closingsFor(situation, tone)));
    return _clean(sentences.join(' '));
  }

  List<String> _reasonsFor(String situation, String tone) {
    final set = _situations[situation]!;
    return switch (tone) {
      'Brutally honest' => set.honest,
      'Ridiculous' => set.ridiculous,
      _ => set.believable,
    };
  }

  List<String> _impactsFor(String situation, String tone) {
    final category = _situations[situation]!.category;
    return _impactSets[category]![tone]!;
  }

  List<String> _closingsFor(String situation, String tone) {
    final category = _situations[situation]!.category;
    return _closingSets[category]![tone]!;
  }

  String _detailSentence(String detail, String tone, bool safeMode) {
    final kind = _classifyDetail(detail);
    final subject = _normaliseDetail(detail, kind);
    final effectiveTone = safeMode && tone == 'Dramatic' ? 'Believable' : tone;
    return _next(
      'detail:$effectiveTone:${kind.name}',
      _detailTemplates[effectiveTone]![kind]!,
    ).replaceAll('{detail}', subject);
  }

  _Score _calculateScore({
    required String situation,
    required String tone,
    required ExcuseLength length,
    required String detail,
    required bool safeMode,
  }) {
    var believability = switch (tone) {
      'Believable' => 87,
      'Dramatic' => 65,
      'Brutally honest' => 94,
      'Ridiculous' => 23,
      _ => 75,
    };

    var riskPoints = switch (tone) {
      'Believable' => 1,
      'Dramatic' => 4,
      'Brutally honest' => 2,
      'Ridiculous' => 6,
      _ => 3,
    };

    if (const {'Work', 'School', 'Appointments'}.contains(situation)) {
      believability += 2;
    }
    if (situation == 'Dating') believability -= 2;

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
      if (wordCount <= 4) believability += 1;
      if (wordCount > 10) {
        believability -= 7;
        riskPoints += 2;
      }
      if (_looksUnusual(detail)) {
        if (tone != 'Ridiculous') believability -= 6;
        riskPoints += 1;
      }
    }

    if (safeMode) {
      believability += tone == 'Ridiculous' ? 1 : 3;
      riskPoints -= 1;
    }

    believability += _random.nextInt(7) - 3;
    final risk = riskPoints.clamp(0, 8) <= 2
        ? FollowUpRisk.low
        : riskPoints.clamp(0, 8) <= 4
            ? FollowUpRisk.medium
            : FollowUpRisk.high;

    return _Score(believability.clamp(1, 99), risk);
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

  String _next(String key, List<String> values) {
    return (_bags[key] ??= _ShuffleBag(values, _random)).next();
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' ,', ',')
      .replaceAll(' .', '.')
      .replaceAll('..', '.')
      .trim();

  static const _openings = <String, List<String>>{
    'Believable': [
      'I’m sorry for the short notice.',
      'I was hoping I could still make this work.',
      'I’ve tried to avoid changing the plan.',
      'I wanted to let you know as early as I could.',
      'Unfortunately, something has changed today.',
      'I need to be realistic about today.',
      'I’ve only just had confirmation of a problem.',
      'I hate having to rearrange at the last minute.',
    ],
    'Dramatic': [
      'I wish I were exaggerating.',
      'The day has unravelled much faster than expected.',
      'A small problem has turned into a complete mess.',
      'Everything has decided to go wrong at once.',
      'I cannot believe this is the update I’m sending.',
      'Today has taken a fairly disastrous turn.',
      'What looked manageable an hour ago is no longer manageable.',
      'I’m dealing with considerably more chaos than planned.',
    ],
    'Brutally honest': [
      'I’m going to be completely honest.',
      'Rather than invent a story, here is the truth.',
      'I owe you a straightforward answer.',
      'There is no dramatic emergency.',
      'I’m not going to dress this up.',
      'The honest version is simple.',
      'I should have said this sooner.',
      'I would rather be direct than make something up.',
    ],
    'Ridiculous': [
      'This sounds invented, but reality has abandoned quality control.',
      'The universe has become unnecessarily involved in my schedule.',
      'I appear to be trapped in a low-budget disaster film.',
      'Against every law of probability, today has become absurd.',
      'Common sense is no longer in charge.',
      'An unreasonable chain of events has taken control of the day.',
      'I would not believe this explanation either, but here we are.',
      'Normal plans have collapsed for reasons nobody can explain.',
    ],
  };

  static const _situations = <String, _SituationSet>{
    'Work': _SituationSet(
      category: _Category.formal,
      believable: [
        'A problem at home needs someone here until it is resolved.',
        'My transport has failed and I do not have a reliable alternative.',
        'A family responsibility has changed at very short notice.',
        'I am dealing with a health issue that makes working unrealistic.',
        'An urgent appointment has moved into the working day.',
      ],
      honest: [
        'I am too depleted to do useful work today.',
        'I have overcommitted and need to reduce the load.',
        'I need a day away rather than pretending I can work effectively.',
      ],
      ridiculous: [
        'My home has become an unofficial command centre for a problem nobody understands.',
        'A household malfunction has promoted me to emergency facilities manager.',
        'My journey has been defeated by transport and one confident pigeon.',
      ],
    ),
    'Plans': _SituationSet(
      category: _Category.social,
      believable: [
        'Something time-sensitive has come up at home.',
        'A family commitment now clashes completely.',
        'My transport arrangements have fallen through.',
        'I am feeling unwell enough that going out would be a bad idea.',
        'My workday has overrun far beyond what I expected.',
      ],
      honest: [
        'I do not have the energy to socialise properly tonight.',
        'I have overbooked myself and need to cancel something.',
        'I need a quiet evening more than another commitment.',
      ],
      ridiculous: [
        'My evening has been requisitioned by events involving no competent adults.',
        'A household task has escalated into a neighbourhood incident.',
        'My transport plan has collapsed like a documentary reconstruction.',
      ],
    ),
    'Family': _SituationSet(
      category: _Category.personal,
      believable: [
        'I need some quiet time to deal with a personal issue.',
        'A last-minute responsibility has landed with me.',
        'I am feeling run down and need to stay home.',
        'I have taken on more than I can realistically manage today.',
      ],
      honest: [
        'I need space tonight and do not want to explain every detail.',
        'I am stretched too thin and need to protect my energy.',
        'I need to say no instead of agreeing out of guilt.',
      ],
      ridiculous: [
        'A family request has evolved into a committee and conflicting instructions.',
        'I have been appointed coordinator of a crisis nobody will define.',
        'The family group chat has become operationally significant.',
      ],
    ),
    'Dating': _SituationSet(
      category: _Category.dating,
      believable: [
        'I am not feeling well enough to be good company tonight.',
        'A personal issue has come up and I need to stay available.',
        'My day has overrun and I am completely drained.',
        'My transport arrangements have fallen apart.',
      ],
      honest: [
        'I am not feeling the date tonight and do not want to fake enthusiasm.',
        'I need to slow this down rather than force another plan.',
        'I am too drained to be present or enjoyable company.',
      ],
      ridiculous: [
        'My evening has been intercepted by a domestic incident with suspicious timing.',
        'A sequence of events has made me less available than a fictional spy.',
        'My transport has entered a committed relationship with unreliability.',
      ],
    ),
    'School': _SituationSet(
      category: _Category.school,
      believable: [
        'I have been unwell and am not fit to concentrate properly.',
        'A medical appointment has been moved unexpectedly.',
        'A family issue needs my attention today.',
        'My transport has been cancelled with no workable alternative.',
      ],
      honest: [
        'I am overwhelmed and need a day to reset.',
        'I have not prepared properly and need to be honest about that.',
        'I am not in a condition to learn effectively today.',
      ],
      ridiculous: [
        'My route to school has been defeated by transport and improbable wildlife.',
        'The morning has become a field trip in crisis management.',
        'My timetable has been overruled by events with no respect for attendance policy.',
      ],
    ),
    'Appointments': _SituationSet(
      category: _Category.appointment,
      believable: [
        'An earlier commitment has overrun and I cannot arrive on time.',
        'My transport has been delayed beyond the appointment window.',
        'I am unwell and need to rearrange rather than attend.',
        'A family responsibility now clashes with the booking.',
      ],
      honest: [
        'I mismanaged the timing and cannot make the appointment.',
        'I am not prepared for the appointment and need to rearrange it.',
        'I have overbooked myself and this is what I need to move.',
      ],
      ridiculous: [
        'My calendar has created two appointments in one body and refuses to negotiate.',
        'The journey has become an obstacle course designed by local government.',
        'A routine booking has attracted an unreasonable number of side quests.',
      ],
    ),
    'Gym': _SituationSet(
      category: _Category.gym,
      believable: [
        'I am feeling run down and training would not be sensible today.',
        'A work commitment has overrun into the session.',
        'My transport has fallen through.',
        'I have picked up a minor strain and need to rest it.',
      ],
      honest: [
        'I do not have the motivation to train today.',
        'I need rest more than I need to force a session.',
        'I organised my day badly and the gym is what has to move.',
      ],
      ridiculous: [
        'My fitness plan has been defeated by a chair, a snack and weak governance.',
        'I sustained an administrative injury while organising the session.',
        'Physical improvement has been blocked by deeply unathletic events.',
      ],
    ),
    'Neighbours': _SituationSet(
      category: _Category.neighbour,
      believable: [
        'I cannot help today because something urgent has come up.',
        'I need to deal with a problem inside my own home first.',
        'I am not available during the time you need me.',
        'A family commitment means I cannot take this on.',
      ],
      honest: [
        'I do not have the capacity to take on another favour.',
        'I need to say no rather than agree and resent it.',
        'I am not comfortable getting involved in this.',
      ],
      ridiculous: [
        'The street has generated more administration than a small country.',
        'A neighbourly request has become a diplomatic incident.',
        'The local group chat has declared an emergency without defining it.',
      ],
    ),
    'Deliveries': _SituationSet(
      category: _Category.delivery,
      believable: [
        'The delivery window has changed and nobody else can be here.',
        'The courier requires a signature and cannot offer a narrower time.',
        'An essential parcel has moved into the middle of the day.',
        'The previous attempt failed and this is the only replacement slot.',
      ],
      honest: [
        'I chose a delivery window that clashes with the plan.',
        'I need the parcel enough that I am prioritising it today.',
        'I organised this badly and now need to stay home.',
      ],
      ridiculous: [
        'The courier has offered a window spanning most of recorded history.',
        'My parcel is travelling through a system powered mainly by mystery.',
        'I am waiting for a driver whose location appears classified.',
      ],
    ),
  };

  static const _impactSets = <_Category, Map<String, List<String>>>{
    _Category.formal: _formalImpacts,
    _Category.school: _formalImpacts,
    _Category.appointment: _formalImpacts,
    _Category.delivery: _formalImpacts,
    _Category.social: _socialImpacts,
    _Category.personal: _personalImpacts,
    _Category.dating: _datingImpacts,
    _Category.gym: _socialImpacts,
    _Category.neighbour: _personalImpacts,
  };

  static const _closingSets = <_Category, Map<String, List<String>>>{
    _Category.formal: _formalClosings,
    _Category.school: _schoolClosings,
    _Category.appointment: _appointmentClosings,
    _Category.delivery: _deliveryClosings,
    _Category.social: _socialClosings,
    _Category.personal: _personalClosings,
    _Category.dating: _datingClosings,
    _Category.gym: _gymClosings,
    _Category.neighbour: _neighbourClosings,
  };

  static const _formalImpacts = <String, List<String>>{
    'Believable': [
      'There is no reliable way for me to meet the original timing.',
      'I cannot give this the focus or reliability it needs.',
    ],
    'Dramatic': [
      'Every revised estimate has already become obsolete.',
      'The timing has collapsed completely and there is no rescue plan.',
    ],
    'Brutally honest': [
      'Pretending I might still manage it would waste more time.',
      'This is my scheduling problem, and I need to correct it directly.',
    ],
    'Ridiculous': [
      'Time itself appears to have rejected the arrangement.',
      'I am losing an argument with both a clock and a sat-nav.',
    ],
  };

  static const _socialImpacts = <String, List<String>>{
    'Believable': [
      'I would rather rearrange than arrive rushed or distracted.',
      'The timing no longer allows me to be properly present.',
    ],
    'Dramatic': [
      'There is no realistic way to rescue the plan without another problem.',
      'The evening has been swallowed by events outside my control.',
    ],
    'Brutally honest': [
      'Forcing it would make the experience worse for everyone.',
      'A clear no is better than an unreliable yes.',
    ],
    'Ridiculous': [
      'My free time is being held hostage by events too strange to summarise.',
      'The day has exceeded its permitted number of complications.',
    ],
  };

  static const _personalImpacts = <String, List<String>>{
    'Believable': [
      'I need to keep the rest of the day simple.',
      'I would not be able to give this the attention it deserves.',
    ],
    'Dramatic': [
      'The situation has become emotionally and practically exhausting.',
      'One more moving part would turn this into a complete mess.',
    ],
    'Brutally honest': [
      'A clear boundary is better than turning up frustrated.',
      'Saying yes when I mean no would not be fair.',
    ],
    'Ridiculous': [
      'I am apparently responsible for logistics and emotional diplomacy.',
      'Nobody knows the plan, but everyone objects to it.',
    ],
  };

  static const _datingImpacts = <String, List<String>>{
    'Believable': [
      'I would rather rearrange than give you a distracted evening.',
      'I cannot arrive in the frame of mind I would want for a date.',
    ],
    'Dramatic': [
      'The evening is impossible to rescue without pretending everything is fine.',
      'I am one complication away from becoming terrible company.',
    ],
    'Brutally honest': [
      'Turning up half-hearted would be unfair to both of us.',
      'Being clear now is kinder than going through the motions.',
    ],
    'Ridiculous': [
      'Romance has been postponed by events with no narrative discipline.',
      'I would arrive with the energy of a hostage reading a statement.',
    ],
  };

  static const _formalClosings = <String, List<String>>{
    'Believable': [
      'I will update you as soon as the position is clearer.',
      'I am sorry for the disruption and will deal with the next steps promptly.',
    ],
    'Dramatic': [
      'I will report back once the situation stops changing by the minute.',
      'I will send an update when there is finally something reliable to say.',
    ],
    'Brutally honest': [
      'I understand the inconvenience and apologise.',
      'I should have communicated this earlier, and I am sorry.',
    ],
    'Ridiculous': [
      'I will report back if the operation ends without a committee.',
      'I hope to return once somebody locates the adult in charge.',
    ],
  };

  static const _socialClosings = <String, List<String>>{
    'Believable': [
      'Can we choose another time when I can actually be present?',
      'I am sorry for the late change and will suggest another time soon.',
    ],
    'Dramatic': [
      'Can we retry when the day has stopped actively fighting me?',
      'I will suggest another time once the chaos has settled.',
    ],
    'Brutally honest': [
      'I know this is inconvenient, but honesty is the better option.',
      'I will suggest another time instead of leaving this vague.',
    ],
    'Ridiculous': [
      'I will reschedule once the universe stops editing my calendar.',
      'I owe you a replacement plan with fewer plot twists.',
    ],
  };

  static const _personalClosings = <String, List<String>>{
    'Believable': [
      'Thank you for giving me a little breathing room.',
      'I will check in properly once I have dealt with everything.',
    ],
    'Dramatic': [
      'I will resurface when the situation is no longer consuming everything.',
      'I need to step back until the immediate mess is under control.',
    ],
    'Brutally honest': [
      'I care, but I still need to keep this boundary.',
      'I will reach out when I have the headspace to do it properly.',
    ],
    'Ridiculous': [
      'I will return once the group chat has lost quorum.',
      'I hope to be released after the next unnecessary vote.',
    ],
  };

  static const _datingClosings = <String, List<String>>{
    'Believable': [
      'Can we reschedule for a time when I can be fully present?',
      'I did not want to disappear or leave you waiting.',
    ],
    'Dramatic': [
      'I would rather retry when my life is in a less destructive phase.',
      'Can we choose another night when the day has stopped unravelling?',
    ],
    'Brutally honest': [
      'I understand if that is disappointing, but honesty is better here.',
      'I will reach out when I can suggest something I genuinely want.',
    ],
    'Ridiculous': [
      'I hope we can retry when my life returns to a calmer genre.',
      'I owe you a date with fewer emergency briefings.',
    ],
  };

  static const _schoolClosings = <String, List<String>>{
    'Believable': ['Please send anything important that I should complete from home.'],
    'Dramatic': ['I will catch up once the morning stops producing new obstacles.'],
    'Brutally honest': ['I will take responsibility for catching up properly.'],
    'Ridiculous': ['Please record this as absent due to excessive plot development.'],
  };

  static const _appointmentClosings = <String, List<String>>{
    'Believable': ['Could we please arrange the next available time?'],
    'Dramatic': ['Please offer the next slot after this scheduling disaster has passed.'],
    'Brutally honest': ['I apologise and understand if there is a cancellation policy.'],
    'Ridiculous': ['Please offer the next time not currently opposed by fate.'],
  };

  static const _deliveryClosings = <String, List<String>>{
    'Believable': ['I will update you once the delivery has been completed.'],
    'Dramatic': ['I will report back when the tracking page stops changing its mind.'],
    'Brutally honest': ['I understand this is not glamorous, but it is the real reason.'],
    'Ridiculous': ['I will be free when the parcel completes its heroic journey.'],
  };

  static const _gymClosings = <String, List<String>>{
    'Believable': ['Can we move the session to another day?'],
    'Dramatic': ['I will return when my schedule and body stop working against me.'],
    'Brutally honest': ['I will reschedule instead of pretending this was unavoidable.'],
    'Ridiculous': ['I will return when my calendar passes its fitness assessment.'],
  };

  static const _neighbourClosings = <String, List<String>>{
    'Believable': ['I am sorry I cannot help this time.'],
    'Dramatic': ['I need to step away before this becomes another emergency.'],
    'Brutally honest': ['A direct no is more useful than an unreliable yes.'],
    'Ridiculous': ['Please remove my name from the emergency rota I never joined.'],
  };

  static const _reassurances = <String, List<String>>{
    'Work': ['I will keep an eye on anything genuinely time-sensitive.'],
    'Plans': ['This is about the timing, not the plan itself.'],
    'Family': ['I am not disappearing; I just need less on my plate today.'],
    'Dating': ['I wanted to tell you directly rather than become vague.'],
    'School': ['I am not treating the missed work casually.'],
    'Appointments': ['I intend to rearrange this promptly.'],
    'Gym': ['I am moving one session, not abandoning the plan.'],
    'Neighbours': ['This is about my availability, not the request itself.'],
    'Deliveries': ['The clash is temporary and specific to today.'],
  };

  static const _detailTemplates = <String, Map<_DetailKind, List<String>>>{
    'Believable': {
      _DetailKind.personOrGroup: [
        'I also need to help {detail} with something that cannot be moved.',
        'Part of the problem involves {detail}, so I need to stay available.',
      ],
      _DetailKind.place: [
        'I also need to deal with an issue at {detail}.',
        'Part of this requires me to remain at {detail}.',
      ],
      _DetailKind.object: [
        'The situation also involves {detail}, which I cannot leave unresolved.',
        'A problem with {detail} has made the original plan unworkable.',
      ],
      _DetailKind.event: [
        'The timing of {detail} has changed unexpectedly.',
        'A last-minute change to {detail} has created the clash.',
      ],
      _DetailKind.subject: [
        'There is also something involving {detail} that needs my attention.',
        'An issue connected to {detail} has added a complication.',
      ],
    },
    'Dramatic': {
      _DetailKind.personOrGroup: [
        'To make matters worse, {detail} is now caught up in this as well.',
        'The latest twist involves coordinating something with {detail}.',
      ],
      _DetailKind.place: [
        'The chaos has expanded to include a problem at {detail}.',
        'The latest complication is unfolding at {detail}.',
      ],
      _DetailKind.object: [
        'The situation now depends on resolving a problem with {detail}.',
        'Every attempt to sort out {detail} has introduced another delay.',
      ],
      _DetailKind.event: [
        'The timing of {detail} has shifted and thrown the day into chaos.',
        'A sudden change involving {detail} has made the clash unavoidable.',
      ],
      _DetailKind.subject: [
        'To make matters worse, the situation now involves {detail}.',
        'A problem involving {detail} has pushed this over the edge.',
      ],
    },
    'Brutally honest': {
      _DetailKind.personOrGroup: [
        'I have chosen to prioritise something involving {detail}.',
        'I need to give my attention to {detail} instead.',
      ],
      _DetailKind.place: [
        'I need to spend that time at {detail} instead.',
        'The practical reason is that I need to be at {detail}.',
      ],
      _DetailKind.object: [
        'I need to sort out {detail} instead of forcing the plan.',
        'The practical issue I am prioritising is {detail}.',
      ],
      _DetailKind.event: [
        'I have decided to prioritise {detail}.',
        'The clash is with {detail}, and I am choosing that commitment.',
      ],
      _DetailKind.subject: [
        'The extra context is that I need to prioritise {detail}.',
        'The thing taking priority today is {detail}.',
      ],
    },
    'Ridiculous': {
      _DetailKind.personOrGroup: [
        'Somehow, {detail} has become involved, which raises new questions.',
        '{detail} has entered the story, and the plot has deteriorated.',
      ],
      _DetailKind.place: [
        'The chaos has spread to {detail} without planning permission.',
        'The next stage of this nonsense is taking place at {detail}.',
      ],
      _DetailKind.object: [
        '{detail} has become the central character in a crisis it did not audition for.',
        'The operation now depends on {detail}, which feels deeply unwise.',
      ],
      _DetailKind.event: [
        '{detail} has been rescheduled by forces that oppose me personally.',
        'The timing of {detail} has collapsed into administrative nonsense.',
      ],
      _DetailKind.subject: [
        'Somehow, {detail} is involved, which raises more questions than it answers.',
        'The situation includes {detail}, because it was not strange enough.',
      ],
    },
  };
}

class _SituationSet {
  const _SituationSet({
    required this.category,
    required this.believable,
    required this.honest,
    required this.ridiculous,
  });

  final _Category category;
  final List<String> believable;
  final List<String> honest;
  final List<String> ridiculous;
}

class _Score {
  const _Score(this.believability, this.risk);

  final num believability;
  final FollowUpRisk risk;
}

enum _Category {
  formal,
  social,
  personal,
  dating,
  school,
  appointment,
  gym,
  neighbour,
  delivery,
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
