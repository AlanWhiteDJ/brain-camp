import 'package:shared_preferences/shared_preferences.dart';

/// Progressive Difficulty System
/// Auto-advances on construction: reads last level from storage, starts at +1.
/// Each game defines its own parameter mapping per level.

class AdaptiveDifficulty {
  final String gameId;
  final int maxLevel;
  final int _startLevel;

  int _level;
  int _totalCorrect = 0;
  int _totalTrials = 0;

  static SharedPreferences? _prefs;
  static const _prefix = 'diff_lv_';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AdaptiveDifficulty({
    required this.gameId,
    this.maxLevel = 255,
    int startLevel = 50,
  }) : _startLevel = startLevel,
       _level = _resolveLevel(gameId, startLevel, maxLevel);

  /// Read stored level. If found, advance by 1 (next level). Otherwise use startLevel.
  static int _resolveLevel(String gameId, int startLevel, int maxLevel) {
    if (_prefs == null) return startLevel;
    final stored = _prefs!.getInt('$_prefix$gameId');
    if (stored == null) return startLevel;
    final next = stored + 1;
    return next > maxLevel ? maxLevel : next;
  }

  /// Save current level (called at session end)
  static Future<void> _saveLevel(String gameId, int level) async {
    if (_prefs == null) return;
    await _prefs!.setInt('$_prefix$gameId', level);
  }

  int get level => _level;
  double get accuracy => _totalTrials > 0 ? _totalCorrect / _totalTrials : 0;
  int get totalTrials => _totalTrials;
  int get totalCorrect => _totalCorrect;

  void recordResult(bool correct) {
    _totalTrials++;
    if (correct) _totalCorrect++;
  }

  /// Persist current level (without advancing — advance happens on next construction)
  Map<String, dynamic> toJson() {
    _saveLevel(gameId, _level);
    return {
      'game_id': gameId,
      'level': _level,
      'total_correct': _totalCorrect,
      'total_trials': _totalTrials,
      'accuracy': accuracy,
    };
  }
}

class DifficultyParams {
  static int levelToInt(int level, int maxLevel, int min, int max) {
    final t = (level - 1) / (maxLevel - 1);
    return (min + (max - min) * t).round();
  }
  static double levelToDouble(int level, int maxLevel, double min, double max) {
    final t = (level - 1) / (maxLevel - 1);
    return min + (max - min) * t;
  }
  static int inverseInt(int level, int maxLevel, int min, int max) {
    return levelToInt(maxLevel - level + 1, maxLevel, min, max);
  }
  static double inverseDouble(int level, int maxLevel, double min, double max) {
    return levelToDouble(maxLevel - level + 1, maxLevel, min, max);
  }
}
