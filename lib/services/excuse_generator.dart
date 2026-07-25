import 'dart:math';

import '../models/generated_excuse.dart';

class ExcuseGenerator {
  ExcuseGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  final List<String> _recentExcuses = [];

  static const int _historyLimit = 20;

  GeneratedExcuse generate({
    required String situation,
    required String tone,
  }) {
    final openings = _openingsByTone[tone] ?? _openingsByTone['Believable']!;
    final problems = _problemsBySituation[situation] ?? _problemsBySituation['Plans']!;
    final consequences =
        _consequencesByTone[tone] ?? _consequencesByTone['Believable']!;
    final closings = _closingsBySituation[situation] ?? _closingsBySituation['Plans']!;

    var text = '';
    for (var attempt = 0; attempt < 30; attempt++) {
      text = '${_pick(openings)} ${_pick(problems)} ${_pick(consequences)} ${_pick(closings)}';
      text = _clean(text);
      if (!_recentExcuses.contains(text)) {
        break;
      }
    }

    _recentExcuses.insert(0, text);
    if (_recentExcuses.length > _historyLimit) {
      _recentExcuses.removeLast();
    }

    final believabilityBase = switch (tone) {
      'Believable' => 86,
      'Dramatic' => 68,
      'Brutally honest' => 96,
      'Ridiculous' => 18,
      _ => 75,
    };

    final risk = switch (tone) {
      'Believable' => FollowUpRisk.low,
      'Dramatic' => FollowUpRisk.high,
      'Brutally honest' => FollowUpRisk.medium,
      'Ridiculous' => FollowUpRisk.high,
      _ => FollowUpRisk.medium,
    };

    final variation = _random.nextInt(9) - 4;

    return GeneratedExcuse(
      text: text,
      situation: situation,
      tone: tone,
      believability: (believabilityBase + variation).clamp(1, 99),
      followUpRisk: risk,
    );
  }

  String _pick(List<String> values) => values[_random.nextInt(values.length)];

  String _clean(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .trim();
  }

  static const Map<String, List<String>> _openingsByTone = {
    'Believable': [
      'I am really sorry for the short notice, but',
      'I hate to do this so late, but',
      'I was hoping I could still make it, but',
      'I need to apologise because',
      'I have just had something unexpected come up and',
      'I did not want to cancel unless I had to, but',
      'I have tried to work around it, but',
      'Unfortunately,',
      'I have only just found out that',
      'I am sorry to change plans, but',
      'This is awkward timing, but',
      'I need to be honest that',
    ],
    'Dramatic': [
      'I wish I were exaggerating, but',
      'Everything has gone wrong at once and',
      'I have just been pulled into a complete mess because',
      'I cannot believe I am writing this, but',
      'The situation has escalated very quickly because',
      'I genuinely thought I could still make it until',
      'This has turned into far more than expected because',
      'I have had one of those nightmare moments where',
      'I am currently dealing with absolute chaos because',
      'I need to disappear for a while because',
      'Against all reasonable odds,',
      'Today has taken a ridiculous turn because',
    ],
    'Brutally honest': [
      'I am going to be completely honest:',
      'Rather than invent something dramatic,',
      'The truthful version is that',
      'I do not have a clever excuse;',
      'I would rather be upfront and say',
      'Honestly,',
      'I am not going to dress this up:',
      'The least complicated explanation is that',
      'I owe you a straightforward answer:',
      'No elaborate story here;',
      'I am choosing honesty today:',
      'The real reason is simple:',
    ],
    'Ridiculous': [
      'This sounds invented, but',
      'In a development nobody could have predicted,',
      'I have somehow become responsible for a crisis because',
      'Please do not ask how, but',
      'Against every law of probability,',
      'I would not believe me either, but',
      'The universe has personally intervened because',
      'I am trapped in a situation involving far too much chaos because',
      'This is the strangest message I have ever sent, but',
      'A deeply unnecessary chain of events means',
      'Today has become a low-budget disaster film because',
      'I have been defeated by circumstances because',
    ],
  };

  static const Map<String, List<String>> _problemsBySituation = {
    'Work': [
      'my boiler has started leaking across the kitchen floor,',
      'a delivery containing an essential replacement part has been moved to today,',
      'my car will not start and roadside assistance cannot give me a firm arrival time,',
      'a family member needs me to take them to an urgent appointment,',
      'there is a plumbing issue at home that cannot be left unattended,',
      'my internet connection has failed while I am waiting for an engineer,',
      'I have developed a migraine that is making it difficult to look at a screen,',
      'the person who was meant to cover a family commitment has cancelled,',
      'my pet has become unwell and the vet wants to see them this morning,',
      'a neighbour has reported water coming through from my property,',
      'public transport on my route has been suspended with no replacement service,',
      'I have been locked out and the locksmith is still on the way,',
    ],
    'Plans': [
      'something urgent has come up at home,',
      'I have been asked to help a family member at very short notice,',
      'the headache I had earlier has become much worse,',
      'my transport has fallen through completely,',
      'a household problem needs someone here until it is fixed,',
      'I have had an unexpected appointment moved into this evening,',
      'my pet is not well and I do not feel comfortable leaving them,',
      'I am waiting for an emergency repair that cannot be rearranged,',
      'I have realised I am coming down with something,',
      'a family commitment has overrun by several hours,',
      'the person I was relying on for childcare has cancelled,',
      'I have been pulled into helping with a situation that cannot wait,',
    ],
    'Family': [
      'I am more exhausted than I expected after this week,',
      'I need a quiet evening to get myself back on track,',
      'something personal has come up that I am not ready to discuss yet,',
      'I have taken on more than I can realistically manage today,',
      'I need to stay home and deal with a practical problem,',
      'I have promised to help someone who genuinely needs me tonight,',
      'I am feeling run down and do not want to pass anything on,',
      'an appointment has been moved and it clashes completely,',
      'I need to sort out a problem at home before it gets worse,',
      'I have had a difficult day and need some space,',
      'a last-minute family responsibility has landed with me,',
      'I cannot give this the time or attention it deserves today,',
    ],
    'Dating': [
      'I am not feeling well enough to be good company tonight,',
      'a family issue has come up and I need to stay available,',
      'my day has overrun badly and I am completely drained,',
      'I have realised I need to slow things down rather than force plans,',
      'my transport arrangements have fallen apart,',
      'I have been called into an unexpected work situation,',
      'I need to deal with something personal before I can properly switch off,',
      'I have picked up a bug and do not want to risk passing it on,',
      'an urgent home repair has taken over the evening,',
      'I am feeling more overwhelmed than I expected today,',
      'a commitment I thought was finished has run much later,',
      'I would not be fully present if we met tonight,',
    ],
    'School': [
      'I have been unwell overnight and have not recovered enough,',
      'a medical appointment has been brought forward unexpectedly,',
      'there has been a family issue that needs my attention,',
      'my transport has been cancelled and no alternative is available,',
      'I have developed a severe migraine this morning,',
      'an urgent appointment clashes with the lesson,',
      'I need to help care for a family member today,',
      'I have had a difficult night and am not fit to concentrate,',
      'a problem at home means I cannot leave yet,',
      'I am waiting for medical advice before going out,',
      'the person responsible for getting me there is unexpectedly unavailable,',
      'I have been advised to rest until my symptoms improve,',
    ],
  };

  static const Map<String, List<String>> _consequencesByTone = {
    'Believable': [
      'so I need to stay here until it is resolved.',
      'which means I cannot get away when I expected.',
      'and I need to deal with it before anything else.',
      'so I am not going to arrive in a useful state.',
      'and there is no reliable way for me to make it on time.',
      'which has taken the rest of my day out of my hands.',
      'so I need to rearrange rather than keep you waiting.',
      'and I cannot responsibly leave it until later.',
      'which means today is no longer workable for me.',
      'so I need to step back from everything else for now.',
    ],
    'Dramatic': [
      'and every attempt to fix it has somehow made it worse.',
      'so I am now coordinating several people and none of them agree on what happens next.',
      'and I have reached the stage where leaving would probably create another emergency.',
      'which has completely swallowed the rest of my day.',
      'and I am currently one phone call away from losing my mind.',
      'so there is no realistic chance of me escaping in time.',
      'and the situation is still actively getting worse.',
      'which means I need to remain here until somebody takes control.',
      'and I am now responsible for preventing a much bigger problem.',
      'so normal plans have temporarily stopped existing.',
    ],
    'Brutally honest': [
      'I do not have the energy to do this properly today.',
      'I need some time alone instead of forcing myself through it.',
      'I overcommitted and should have said so earlier.',
      'I would rather rearrange than turn up distracted and resentful.',
      'I need to protect the small amount of energy I have left.',
      'I am not in the right frame of mind to be useful or enjoyable company.',
      'I need to say no rather than produce a complicated story.',
      'I underestimated how much I already had on my plate.',
      'I am choosing rest instead of pretending everything is fine.',
      'I simply do not want to rush into something I cannot give proper attention.',
    ],
    'Ridiculous': [
      'and I am apparently the only person qualified to restore order.',
      'which has resulted in three phone calls, one missing key and an angry pigeon.',
      'and leaving now would violate at least two promises and possibly maritime law.',
      'so I have been promoted to emergency coordinator without my consent.',
      'and the situation now involves a ladder, a birthday cake and no clear adult supervision.',
      'which means I cannot leave until the neighbourhood group chat calms down.',
      'and I have somehow become the main witness despite seeing absolutely nothing.',
      'so my evening is being held hostage by events too strange to summarise.',
      'and every available solution requires equipment I do not own.',
      'which has escalated beyond anything a reasonable person could have planned for.',
    ],
  };

  static const Map<String, List<String>> _closingsBySituation = {
    'Work': [
      'I will keep you updated as soon as I know more.',
      'I appreciate your understanding and will catch up on anything urgent.',
      'I will message again once the situation is clearer.',
      'Please send over anything time-sensitive and I will respond when I can.',
      'I am sorry for the disruption and will make sure nothing is left hanging.',
      'I will confirm later whether I am able to return online.',
      'Thank you for bearing with me today.',
      'I will pick this up properly as soon as I am able.',
    ],
    'Plans': [
      'Can we rearrange when things are less chaotic?',
      'I am sorry to let you down at the last minute.',
      'I will make it up to you when we reschedule.',
      'I hope we can find another day soon.',
      'I did not want to keep you waiting or cancel even later.',
      'Thank you for understanding.',
      'I will message when I know what the rest of the evening looks like.',
      'Let us choose another time when I can actually be present.',
    ],
    'Family': [
      'I hope you understand that I need to take tonight for myself.',
      'I would rather rearrange than arrive distracted.',
      'I will check in properly once I have dealt with everything.',
      'Thank you for giving me a little breathing room.',
      'I am sorry this is so last minute.',
      'I will make sure we find another time soon.',
      'I do not want to promise more than I can manage today.',
      'I appreciate you understanding.',
    ],
    'Dating': [
      'I would rather rearrange than give you a half-hearted evening.',
      'I hope we can choose another night soon.',
      'I am sorry for the late change and completely understand the inconvenience.',
      'Can we reschedule for a time when I can be properly present?',
      'I did not want to leave you waiting or cancel at the last second.',
      'I hope this does not come across as dismissive.',
      'I will message tomorrow when things are clearer.',
      'You deserve a better version of me than I could bring tonight.',
    ],
    'School': [
      'I will catch up on the work as soon as possible.',
      'Please let me know what I need to complete.',
      'I am sorry for the short notice.',
      'I will provide any required information when I am able.',
      'I will make sure I do not fall behind.',
      'Thank you for understanding.',
      'I will check the lesson materials later today.',
      'Please send over anything that needs urgent attention.',
    ],
  };
}