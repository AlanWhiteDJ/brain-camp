/// Progressive Difficulty System
/// Simple level advancement: one session = one level up
/// Each game defines its own parameter mapping per level.

class AdaptiveDifficulty {
  final String gameId;
  final int maxLevel;

  int _level;
  int _totalCorrect = 0;
  int _totalTrials = 0;

  AdaptiveDifficulty({
    required this.gameId,
    this.maxLevel = 255,
    int startLevel = 50,
  }) : _level = startLevel;

  int get level => _level;
  double get accuracy => _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;
  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;

  /// Record a single trial result (for stats only)
  void recordResult(bool correct) {
    _totalTrials++;
    if (correct) _totalCorrect++;
  }

  /// Advance one level after completing a session (capped at maxLevel)
  /// Returns the new level
  int advanceLevel() {
    if (_level < maxLevel) _level++;
    return _level;
  }

  Map<String, dynamic> toJson() {
    if (_level < maxLevel) _level++;
    return {
        'game_id': gameId,
        'level': _level,
        'total_correct': _totalCorrect,
        'total_trials': _totalTrials,
        'accuracy': accuracy,
      };
  }
}

/// Parameter mapper: maps difficulty level to game-specific parameters
class DifficultyParams {
  /// Linearly interpolate parameter from level range [1..maxLevel]
  /// to value range [min..max]
  static int levelToInt(int level, int maxLevel, int min, int max) {
    final t = (level - 1) / (maxLevel - 1);
    return (min + (max - min) * t).round();
  }

  static double levelToDouble(int level, int maxLevel, double min, double max) {
    final t = (level - 1) / (maxLevel - 1);
    return min + (max - min) * t;
  }

  /// Inverse: easier at lower levels (higher level = harder = smaller value)
  static int inverseInt(int level, int maxLevel, int min, int max) {
    return levelToInt(maxLevel - level + 1, maxLevel, min, max);
  }

  static double inverseDouble(int level, int maxLevel, double min, double max) {
    return levelToDouble(maxLevel - level + 1, maxLevel, min, max);
  }
}
