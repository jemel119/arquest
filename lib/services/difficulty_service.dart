class DifficultyService {
  static const int _fastThreshold = 120;   // under 2 min = too easy
  static const int _slowThreshold = 600;   // over 10 min = too hard
  static const int _missThreshold = 3;     // 3+ misses = too hard

  // Returns the recommended difficulty level based on recent performance.
  // Possible return values: 'easy', 'medium', 'hard'
  String recommendNextDifficulty({
    required int recentCompletionTimeSeconds,
    required int missedAttempts,
    required String currentDifficulty,
  }) {
    // Player is struggling — step down one level
    if (missedAttempts >= _missThreshold ||
        recentCompletionTimeSeconds > _slowThreshold) {
      if (currentDifficulty == 'hard') return 'medium';
      if (currentDifficulty == 'medium') return 'easy';
      return 'easy';
    }

    // Player is breezing through — step up one level
    if (recentCompletionTimeSeconds < _fastThreshold &&
        missedAttempts == 0) {
      if (currentDifficulty == 'easy') return 'medium';
      if (currentDifficulty == 'medium') return 'hard';
      return 'hard';
    }

    // Within normal range — keep the same difficulty
    return currentDifficulty;
  }

  // Returns a human-readable explanation of the recommendation.
  // Useful for surfacing the reasoning in the UI.
  String getRecommendationReason({
    required int recentCompletionTimeSeconds,
    required int missedAttempts,
  }) {
    if (missedAttempts >= _missThreshold) {
      return 'You missed $_missedAttempts clues — try an easier quest next.';
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