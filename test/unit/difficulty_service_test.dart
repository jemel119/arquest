import 'package:flutter_test/flutter_test.dart';
import 'package:arquest/services/difficulty_service.dart';

void main() {
  group('DifficultyService', () {
    late DifficultyService service;

    setUp(() {
      service = DifficultyService();
    });

    // ── recommendNextDifficulty ─────────────────────────────────────────────

    group('recommendNextDifficulty', () {
      // Struggling scenarios — should step down
      test('returns medium when hard and missed attempts >= 3', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 3,
          currentDifficulty: 'hard',
        );
        expect(result, 'medium');
      });

      test('returns easy when medium and missed attempts >= 3', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 4,
          currentDifficulty: 'medium',
        );
        expect(result, 'easy');
      });

      test('returns easy when already easy and missed attempts >= 3', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 5,
          currentDifficulty: 'easy',
        );
        expect(result, 'easy');
      });

      test('returns easier when completion time exceeds slow threshold', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 601,
          missedAttempts: 0,
          currentDifficulty: 'hard',
        );
        expect(result, 'medium');
      });

      test('returns easy when medium and time exceeds slow threshold', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 700,
          missedAttempts: 0,
          currentDifficulty: 'medium',
        );
        expect(result, 'easy');
      });

      // Breezing through scenarios — should step up
      test('returns medium when easy and time under fast threshold with no misses', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 90,
          missedAttempts: 0,
          currentDifficulty: 'easy',
        );
        expect(result, 'medium');
      });

      test('returns hard when medium and time under fast threshold with no misses', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 100,
          missedAttempts: 0,
          currentDifficulty: 'medium',
        );
        expect(result, 'hard');
      });

      test('returns hard when already hard and time under fast threshold with no misses', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 50,
          missedAttempts: 0,
          currentDifficulty: 'hard',
        );
        expect(result, 'hard');
      });

      // Normal range scenarios — should stay the same
      test('keeps medium when within normal range', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 1,
          currentDifficulty: 'medium',
        );
        expect(result, 'medium');
      });

      test('keeps easy when within normal range', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 250,
          missedAttempts: 2,
          currentDifficulty: 'easy',
        );
        expect(result, 'easy');
      });

      test('keeps hard when within normal range', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 400,
          missedAttempts: 0,
          currentDifficulty: 'hard',
        );
        expect(result, 'hard');
      });

      // Edge cases — exactly on the thresholds
      test('does not step up when fast but has 1 miss', () {
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 90,
          missedAttempts: 1,
          currentDifficulty: 'easy',
        );
        expect(result, 'easy');
      });

      test('does not step down when time is exactly at slow threshold', () {
        // 600 is not > 600, so should stay the same
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 600,
          missedAttempts: 0,
          currentDifficulty: 'medium',
        );
        expect(result, 'medium');
      });

      test('steps up when time is exactly at fast threshold boundary', () {
        // 119 is < 120, should step up
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 119,
          missedAttempts: 0,
          currentDifficulty: 'easy',
        );
        expect(result, 'medium');
      });

      test('does not step up when time is exactly at fast threshold', () {
        // 120 is not < 120, should stay the same
        final result = service.recommendNextDifficulty(
          recentCompletionTimeSeconds: 120,
          missedAttempts: 0,
          currentDifficulty: 'easy',
        );
        expect(result, 'easy');
      });
    });

    // ── getRecommendationReason ─────────────────────────────────────────────

    group('getRecommendationReason', () {
      test('returns miss-based reason when missed attempts >= 3', () {
        final result = service.getRecommendationReason(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 3,
        );
        expect(result, contains('missed'));
      });

      test('returns time-based reason when completion time exceeds threshold', () {
        final result = service.getRecommendationReason(
          recentCompletionTimeSeconds: 700,
          missedAttempts: 0,
        );
        expect(result, contains('minutes'));
      });

      test('returns encouragement when fast with no misses', () {
        final result = service.getRecommendationReason(
          recentCompletionTimeSeconds: 90,
          missedAttempts: 0,
        );
        expect(result, contains('harder'));
      });

      test('returns steady message when within normal range', () {
        final result = service.getRecommendationReason(
          recentCompletionTimeSeconds: 300,
          missedAttempts: 1,
        );
        expect(result, contains('same'));
      });
    });
  });
}