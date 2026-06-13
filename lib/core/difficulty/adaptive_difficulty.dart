/// Adaptive Difficulty System
/// Common difficulty leveling for all training games
///
/// Adjusts up when performance is good, down when struggling.
/// Each game defines its own parameter mapping per level.

import 'dart:math';

class AdaptiveDifficulty {
  final String gameId;
  final int maxLevel;
  final double upThreshold;  // accuracy above this → level up
  final double downThreshold; // accuracy below this → level down
  final int windowSize;       // trials to evaluate

  int _level;
  final List<bool> _recentResults = [];
  int _totalCorrect = 0;
  int _totalTrials = 0;

  AdaptiveDifficulty({
    required this.gameId,
    this.maxLevel = 10,
    this.upThreshold = 0.80,
    this.downThreshold = 0.55,
    this.windowSize = 8,
    int startLevel = 3,
  }) : _level = startLevel;

  int get level => _level;
  double get progress => _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;
  double get recentAccuracy {
    if (_recentResults.isEmpty) return 1.0;
    return _recentResults.where((r) => r).length / _recentResults.length;
  }

  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;

  /// Record result and adjust difficulty
  int recordResult(bool correct) {
    _totalTrials++;
    if (correct) _totalCorrect++;
    _recentResults.add(correct);
    if (_recentResults.length > windowSize) _recentResults.removeAt(0);

    // Evaluate window
    if (_recentResults.length >= windowSize) {
      final acc = recentAccuracy;
      if (acc >= upThreshold && _level < maxLevel) {
        _level++;
      } else if (acc <= downThreshold && _level > 1) {
        _level--;
      }
      // Clear window after adjustment
      _recentResults.clear();
    }

    return _level;
  }

  Map<String, dynamic> toJson() => {
        'game_id': gameId,
        'level': _level,
        'total_correct': _totalCorrect,
        'total_trials': _totalTrials,
        'accuracy': progress,
      };
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

  /// Inverse: easier at lower levels
  static int inverseInt(int level, int maxLevel, int min, int max) {
    return levelToInt(maxLevel - level + 1, maxLevel, min, max);
  }

  static double inverseDouble(int level, int maxLevel, double min, double max) {
    return levelToDouble(maxLevel - level + 1, maxLevel, min, max);
  }
}
