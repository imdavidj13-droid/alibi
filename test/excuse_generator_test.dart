import 'dart:math';

import 'package:alibi/models/generated_excuse.dart';
import 'package:alibi/services/excuse_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generator returns complete situation-specific excuse', () {
    final generator = ExcuseGenerator(random: Random(7));

    final excuse = generator.generate(
      situation: 'Work',
      tone: 'Believable',
    );

    expect(excuse.text, isNotEmpty);
    expect(excuse.situation, 'Work');
    expect(excuse.tone, 'Believable');
    expect(excuse.believability, inInclusiveRange(1, 99));
    expect(excuse.followUpRisk, FollowUpRisk.low);
  });

  test('generator avoids immediate duplicate results', () {
    final generator = ExcuseGenerator(random: Random(12));

    final first = generator.generate(
      situation: 'Plans',
      tone: 'Ridiculous',
    );
    final second = generator.generate(
      situation: 'Plans',
      tone: 'Ridiculous',
    );

    expect(second.text, isNot(first.text));
  });

  test('generator produces a unique first cycle', () {
    final generator = ExcuseGenerator(random: Random(22));
    final results = <String>{};

    for (var index = 0; index < 20; index++) {
      final excuse = generator.generate(
        situation: 'Work',
        tone: 'Believable',
      );
      results.add(excuse.text);
    }

    expect(results, hasLength(20));
  });
}
