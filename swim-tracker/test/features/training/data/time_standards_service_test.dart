import 'package:flutter_test/flutter_test.dart';
import 'package:swim_tracker_mobile/src/features/training/domain/time_standard.dart';
import 'package:swim_tracker_mobile/src/features/training/data/time_standards_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:swim_tracker_mobile/src/features/training/data/time_standards_repository.dart';

@GenerateMocks([TimeStandardsRepository])
import 'time_standards_service_test.mocks.dart';

void main() {
  late TimeStandardsService service;
  late MockTimeStandardsRepository mockRepository;

  setUp(() {
    mockRepository = MockTimeStandardsRepository();
    service = TimeStandardsService(mockRepository);
  });

  group('TimeStandardsService', () {
    group('calculateStandardInfo', () {
      test('identifies current standard correctly', () async {
        // Mock standards for 100 Free Boys 13-14 SCY
        final standards = [
          TimeStandard(
            id: '1',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.b,
            timeSeconds: 63.99,
          ),
          TimeStandard(
            id: '2',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.bb,
            timeSeconds: 58.99,
          ),
          TimeStandard(
            id: '3',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.a,
            timeSeconds: 53.99,
          ),
        ];

        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => standards);

        // Test swimmer with 56.5 seconds (between BB and A)
        final result = await service.calculateStandardInfo(
          currentTime: 56.5,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result.currentStandard, StandardLevel.bb);
        expect(result.nextStandard, StandardLevel.a);
        expect(result.timeToNextStandard, isNotNull);
        expect(result.hasAchievedStandard, isTrue);
        expect(result.canImprove, isTrue);
      });

      test('handles no standard achieved yet', () async {
        final standards = [
          TimeStandard(
            id: '1',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.b,
            timeSeconds: 63.99,
          ),
        ];

        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => standards);

        // Test slow swimmer (65 seconds - slower than B)
        final result = await service.calculateStandardInfo(
          currentTime: 65.0,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result.currentStandard, isNull);
        expect(result.nextStandard, StandardLevel.b);
        expect(result.hasAchievedStandard, isFalse);
        expect(result.canImprove, isTrue);
      });

      test('handles max standard achieved', () async {
        final standards = [
          TimeStandard(
            id: '1',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.aaaaa,
            timeSeconds: 46.99,
          ),
        ];

        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => standards);

        // Test elite swimmer (45 seconds - faster than AAAAA)
        final result = await service.calculateStandardInfo(
          currentTime: 45.0,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result.currentStandard, StandardLevel.aaaaa);
        expect(result.nextStandard, isNull);
        expect(result.canImprove, isFalse);
      });

      test('handles empty standards list', () async {
        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => []);

        final result = await service.calculateStandardInfo(
          currentTime: 55.0,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result.currentStandard, isNull);
        expect(result.nextStandard, isNull);
        expect(result.hasAchievedStandard, isFalse);
        expect(result.canImprove, isFalse);
      });
    });

    group('formatTimeDifference', () {
      test('formats seconds correctly', () {
        expect(service.formatTimeDifference(2.5), '2.50s');
        expect(service.formatTimeDifference(45.99), '45.99s');
      });

      test('formats minutes and seconds correctly', () {
        expect(service.formatTimeDifference(65.5), '1:05.50');
        expect(service.formatTimeDifference(125.25), '2:05.25');
      });

      test('handles negative times', () {
        expect(service.formatTimeDifference(-2.5), '-2.50s');
        expect(service.formatTimeDifference(-65.5), '-1:05.50');
      });
    });

    group('getSuggestedGoalTime', () {
      test('suggests next standard time', () async {
        final standards = [
          TimeStandard(
            id: '1',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.bb,
            timeSeconds: 58.99,
          ),
          TimeStandard(
            id: '2',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.a,
            timeSeconds: 53.99,
          ),
        ];

        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => standards);

        when(mockRepository.getStandard(
          gender: 'M',
          ageGroup: '13-14',
          course: 'SCY',
          event: '100 Free',
          standardLevel: StandardLevel.a,
        )).thenAnswer((_) async => standards[1]);

        final result = await service.getSuggestedGoalTime(
          currentBestTime: 57.0,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result, 53.99);
      });

      test('suggests 1% improvement when at max level', () async {
        final standards = [
          TimeStandard(
            id: '1',
            gender: 'M',
            ageGroup: '13-14',
            course: 'SCY',
            event: '100 Free',
            stroke: 'Free',
            distance: 100,
            standardLevel: StandardLevel.aaaaa,
            timeSeconds: 46.99,
          ),
        ];

        when(mockRepository.getStandardsByStrokeDistance(
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        )).thenAnswer((_) async => standards);

        final result = await service.getSuggestedGoalTime(
          currentBestTime: 45.0,
          gender: 'M',
          ageGroup: '13-14',
          stroke: 'Free',
          distance: 100,
          course: 'SCY',
        );

        expect(result, closeTo(44.55, 0.01)); // 45 * 0.99
      });
    });
  });

  group('StandardLevel', () {
    test('ranks are correct', () {
      expect(StandardLevel.b.rank, 1);
      expect(StandardLevel.bb.rank, 2);
      expect(StandardLevel.a.rank, 3);
      expect(StandardLevel.aa.rank, 4);
      expect(StandardLevel.aaa.rank, 5);
      expect(StandardLevel.aaaa.rank, 6);
      expect(StandardLevel.aaaaa.rank, 7);
    });

    test('nextLevel returns correct level', () {
      expect(StandardLevel.b.nextLevel, StandardLevel.bb);
      expect(StandardLevel.bb.nextLevel, StandardLevel.a);
      expect(StandardLevel.a.nextLevel, StandardLevel.aa);
      expect(StandardLevel.aa.nextLevel, StandardLevel.aaa);
      expect(StandardLevel.aaa.nextLevel, StandardLevel.aaaa);
      expect(StandardLevel.aaaa.nextLevel, StandardLevel.aaaaa);
      expect(StandardLevel.aaaaa.nextLevel, isNull);
    });

    test('fromString parses correctly', () {
      expect(StandardLevel.fromString('B'), StandardLevel.b);
      expect(StandardLevel.fromString('BB'), StandardLevel.bb);
      expect(StandardLevel.fromString('A'), StandardLevel.a);
      expect(StandardLevel.fromString('AA'), StandardLevel.aa);
      expect(StandardLevel.fromString('AAA'), StandardLevel.aaa);
      expect(StandardLevel.fromString('AAAA'), StandardLevel.aaaa);
      expect(StandardLevel.fromString('AAAAA'), StandardLevel.aaaaa);
    });
  });
}
