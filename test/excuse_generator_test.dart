import 'dart:math';

import 'package:alibi/models/excuse_length.dart';
import 'package:alibi/models/generated_excuse.dart';
import 'package:alibi/services/excuse_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coherent excuse generator', () {
    test('supports every situation, tone and length combination', () {
      final generator = ExcuseGenerator(random: Random(7));

      for (final situation in ExcuseGenerator.situations) {
        for (final tone in ExcuseGenerator.tones) {
          for (final length in ExcuseLength.values) {
            final excuse = generator.generate(
              situation: situation,
              tone: tone,
              length: length,
              detail: 'my car',
              safeMode: false,
            );

            expect(excuse.text, isNotEmpty);
            expect(RegExp(r'[.!?]$').hasMatch(excuse.text), isTrue);
            expect(excuse.text.contains('  '), isFalse);
            expect(excuse.text.contains('..'), isFalse);
            expect(excuse.situation, situation);
            expect(excuse.tone, tone);
            expect(excuse.believability, inInclusiveRange(1, 99));
          }
        }
      }
    });

    test('length modes produce naturally different message sizes', () {
      final shortGenerator = ExcuseGenerator(random: Random(20));
      final standardGenerator = ExcuseGenerator(random: Random(20));
      final detailedGenerator = ExcuseGenerator(random: Random(20));

      final short = shortGenerator.generate(
        situation: 'Plans',
        tone: 'Believable',
        length: ExcuseLength.short,
      );
      final standard = standardGenerator.generate(
        situation: 'Plans',
        tone: 'Believable',
        length: ExcuseLength.standard,
      );
      final detailed = detailedGenerator.generate(
        situation: 'Plans',
        tone: 'Believable',
        length: ExcuseLength.detailed,
      );

      expect(short.text.length, lessThan(standard.text.length));
      expect(standard.text.length, lessThan(detailed.text.length));
    });

    test('tone selections remain distinct when safe mode is enabled', () {
      final dramatic = ExcuseGenerator(random: Random(4)).generate(
        situation: 'Work',
        tone: 'Dramatic',
        detail: 'my car',
        safeMode: true,
      );
      final believable = ExcuseGenerator(random: Random(4)).generate(
        situation: 'Work',
        tone: 'Believable',
        detail: 'my car',
        safeMode: true,
      );

      expect(dramatic.tone, 'Dramatic');
      expect(believable.tone, 'Believable');
      expect(dramatic.text, isNot(believable.text));
    });

    test('lowercase team names are capitalised and woven into grammar', () {
      final excuse = ExcuseGenerator(random: Random(11)).generate(
        situation: 'Plans',
        tone: 'Ridiculous',
        detail: 'arsenal women',
        safeMode: false,
      );

      expect(excuse.text, contains('Arsenal Women'));
      expect(excuse.text.toLowerCase().startsWith('arsenal women'), isFalse);
      expect(excuse.text, isNot(startsWith('Arsenal Women.')));
    });

    test('school honesty stays on one coherent explanation', () {
      final excuse = ExcuseGenerator(random: Random(9)).generate(
        situation: 'School',
        tone: 'Brutally honest',
        length: ExcuseLength.detailed,
        detail: 'my dog Bruno',
      );

      expect(excuse.text, contains('not prepared properly'));
      expect(excuse.text, contains('my dog Bruno'));
      expect(excuse.text, contains('catching up'));
      expect(excuse.text, isNot(contains('scheduling problem')));
      expect(excuse.text, isNot(contains('original plan')));
      expect(excuse.text, isNot(contains('work reliably')));
    });

    test('detail remains secondary to the selected scenario', () {
      final excuse = ExcuseGenerator(random: Random(5)).generate(
        situation: 'School',
        tone: 'Brutally honest',
        detail: 'my dog Bruno',
      );

      final reasonIndex = excuse.text.indexOf('not prepared properly');
      final detailIndex = excuse.text.indexOf('my dog Bruno');

      expect(reasonIndex, greaterThanOrEqualTo(0));
      expect(detailIndex, greaterThan(reasonIndex));
    });

    test(
      'classifies common detail types without copying raw fragments first',
      () {
        const details = [
          'my car',
          'London office',
          'a delivery',
          'Sam Taylor',
          'the concert',
        ];

        for (final detail in details) {
          final excuse = ExcuseGenerator(
            random: Random(detail.length),
          ).generate(situation: 'Work', tone: 'Believable', detail: detail);

          expect(excuse.text.toLowerCase(), contains(detail.toLowerCase()));
          expect(
            excuse.text.toLowerCase().startsWith(detail.toLowerCase()),
            isFalse,
          );
        }
      },
    );

    test('believability and risk reflect the selected tone', () {
      final believable = ExcuseGenerator(
        random: Random(3),
      ).generate(situation: 'Work', tone: 'Believable');
      final dramatic = ExcuseGenerator(
        random: Random(3),
      ).generate(situation: 'Work', tone: 'Dramatic', safeMode: false);
      final honest = ExcuseGenerator(
        random: Random(3),
      ).generate(situation: 'Work', tone: 'Brutally honest');
      final ridiculous = ExcuseGenerator(
        random: Random(3),
      ).generate(situation: 'Work', tone: 'Ridiculous', safeMode: false);

      expect(honest.believability, greaterThan(believable.believability));
      expect(believable.believability, greaterThan(dramatic.believability));
      expect(dramatic.believability, greaterThan(ridiculous.believability));
      expect(believable.followUpRisk, FollowUpRisk.low);
      expect(ridiculous.followUpRisk, FollowUpRisk.high);
    });

    test('safe mode improves score and lowers risk where possible', () {
      final safe = ExcuseGenerator(random: Random(13)).generate(
        situation: 'Dating',
        tone: 'Dramatic',
        length: ExcuseLength.detailed,
        detail: 'a dragon',
        safeMode: true,
      );
      final unsafe = ExcuseGenerator(random: Random(13)).generate(
        situation: 'Dating',
        tone: 'Dramatic',
        length: ExcuseLength.detailed,
        detail: 'a dragon',
        safeMode: false,
      );

      expect(safe.believability, greaterThan(unsafe.believability));
      expect(
        safe.followUpRisk.index,
        lessThanOrEqualTo(unsafe.followUpRisk.index),
      );
    });

    test('avoids immediate duplicate results', () {
      final generator = ExcuseGenerator(random: Random(12));

      final first = generator.generate(situation: 'Plans', tone: 'Ridiculous');
      final second = generator.generate(situation: 'Plans', tone: 'Ridiculous');

      expect(second.text, isNot(first.text));
    });

    test('falls back safely for unsupported values', () {
      final excuse = ExcuseGenerator(
        random: Random(2),
      ).generate(situation: 'Unknown', tone: 'Unknown');

      expect(excuse.situation, 'Plans');
      expect(excuse.tone, 'Believable');
      expect(excuse.text, isNotEmpty);
    });
  });
}
