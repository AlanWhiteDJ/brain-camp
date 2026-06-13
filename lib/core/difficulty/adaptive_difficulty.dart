import 'package:shared_preferences/shared_preferences.dart';

/// Progressive Difficulty System
/// Self-persisting: reads level from storage on init, auto-advances on save.
/// Each game defines its own parameter mapping per level.

class AdaptiveDifficulty {
  final String gameId;
  final int maxLevel;
  final int _startLevel; // fallback if no stored level

  int _level;
  int _totalCorrect = 0;
  int _totalTrials = 0;

  static SharedPreferences? _prefs;
  static const _prefix = 'diff_lv_';

  /// Must be called once at app startup
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AdaptiveDifficulty({
    required this.gameId,
    this.maxLevel = 255,
    int startLevel = 50,
  }) : _startLevel = startLevel,
       _level = _loadStoredLevel(gameId, startLevel);

  static int _loadStoredLevel(String gameId, int fallback) {
    if (_prefs == null) return fallback;
    return _prefs!.getInt('$_prefix$gameId') ?? fallback;
  }

  static Future<void> _saveStoredLevel(String gameId, int level) async {
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

  /// Call at session end: advance level and persist
  void advanceLevel() {
    if (_level < maxLevel) _level++;
    _saveStoredLevel(gameId, _level);
  }

  Map<String, dynamic> toJson() {
    advanceLevel(); // auto-advance + persist
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
