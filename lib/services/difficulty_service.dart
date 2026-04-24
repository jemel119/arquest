class DifficultyService {
  static const int _fastThreshold = 120;
  static const int _slowThreshold = 600;
  static const int _missThreshold = 3;

  String recommendNextDifficulty({
    required int recentCompletionTimeSeconds,
    required int missedAttempts,
    required String currentDifficulty,
  }) {
    if (missedAttempts >= _missThreshold ||
        recentCompletionTimeSeconds > _slowThreshold) {
      if (currentDifficulty == 'hard') return 'medium';
      if (currentDifficulty == 'medium') return 'easy';
      return 'easy';
    }

    if (recentCompletionTimeSeconds < _fastThreshold &&
        missedAttempts == 0) {
      if (currentDifficulty == 'easy') return 'medium';
      if (currentDifficulty == 'medium') return 'hard';
      return 'hard';
    }

    return currentDifficulty;
  }

  String getRecommendationReason({
    required int recentCompletionTimeSeconds,
    required int missedAttempts,
  }) {
    if (missedAttempts >= _missThreshold) {
      return 'You missed $missedAttempts clues — try an easier quest next.';
    }
    if (recentCompletionTimeSeconds > _slowThreshold) {
      final mins = (recentCompletionTimeSeconds / 60).round();
      return 'That took $mins minutes — an easier quest might suit you better.';
    }
    if (recentCompletionTimeSeconds < _fastThreshold && missedAttempts == 0) {
      return 'You nailed it with no misses — ready for a harder challenge!';
    }
    return 'Good performance — stick with the same difficulty.';
  }
}