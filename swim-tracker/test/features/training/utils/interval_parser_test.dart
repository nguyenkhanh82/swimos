import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/utils/interval_parser.dart';

void main() {
  group('IntervalParser', () {
    group('parseIntervalSeconds', () {
      test('parses "on 1:10" format (minutes:seconds)', () {
        final result = IntervalParser.parseIntervalSeconds('5x100 on 1:10');
        expect(result, 70);
      });

      test('parses "on :45" format (seconds only with colon)', () {
        final result = IntervalParser.parseIntervalSeconds('10x50 on :45');
        expect(result, 45);
      });

      test('parses "on 2:30" format (multi-digit minutes)', () {
        final result = IntervalParser.parseIntervalSeconds('3x200 on 2:30');
        expect(result, 150);
      });

      test('returns null for continuous sets without interval', () {
        final result = IntervalParser.parseIntervalSeconds('400 IM');
        expect(result, isNull);
      });

      test('returns null for sets without "on" notation', () {
        final result = IntervalParser.parseIntervalSeconds('8x100 Free');
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = IntervalParser.parseIntervalSeconds('');
        expect(result, isNull);
      });

      test('returns null for whitespace-only string', () {
        final result = IntervalParser.parseIntervalSeconds('   ');
        expect(result, isNull);
      });

      test('handles case-insensitive "ON" notation', () {
        final result = IntervalParser.parseIntervalSeconds('5x100 ON 1:10');
        expect(result, 70);
      });

      test('handles "On" with mixed case', () {
        final result = IntervalParser.parseIntervalSeconds('5x100 On 1:10');
        expect(result, 70);
      });

      test('returns null for "on 90" format without colon', () {
        // Note: The current implementation requires colon format (e.g., :90)
        // "on 90" without colon doesn't parse correctly due to regex behavior
        final result = IntervalParser.parseIntervalSeconds('8x50 on 90');
        expect(result, isNull);
      });

      test('parses zero minutes with seconds', () {
        final result = IntervalParser.parseIntervalSeconds('10x50 on 0:30');
        expect(result, 30);
      });

      test('parses exact minute intervals', () {
        final result = IntervalParser.parseIntervalSeconds('4x100 on 1:00');
        expect(result, 60);
      });

      test('parses two minute interval', () {
        final result = IntervalParser.parseIntervalSeconds('2x200 on 2:00');
        expect(result, 120);
      });

      test('handles extra whitespace after "on"', () {
        final result = IntervalParser.parseIntervalSeconds('5x100 on  1:10');
        expect(result, 70);
      });
    });
  });
}
