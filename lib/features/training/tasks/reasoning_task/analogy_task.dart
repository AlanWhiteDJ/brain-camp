import 'dart:math';
import '../../../../core/difficulty/adaptive_difficulty.dart';

/// Analogy Task — "比一比"
///
/// A:B :: C:? — the child sees a pair relationship and must
/// complete a second pair with the same relationship.
///
/// Difficulty scales relation abstractness:
///   L1-3  → Concrete: animal-home, animal-sound, object-use
///   L4-6  → Part-whole, function, category membership
///   L7-8  → Opposites, tools, cause-effect
///   L9-10 → Abstract mappings, measurement, hierarchy

class AnalogyTask {
  final AdaptiveDifficulty difficulty;
  final Random _random = Random();

  static const int totalTrials = 20;

  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];
  int _trialStartMs = 0;

  // Current trial
  String _emojiA = '';
  String _emojiB = '';
  String _emojiC = '';
  String _emojiD = ''; // correct answer
  String _relationHint = '';
  List<String> _options = [];
  int _correctOptionIndex = -1;

  AnalogyTask({required this.difficulty});

  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  int get level => difficulty.level;
  String get emojiA => _emojiA;
  String get emojiB => _emojiB;
  String get emojiC => _emojiC;
  String get emojiD => _emojiD;
  String get relationHint => _relationHint;
  List<String> get options => List.unmodifiable(_options);
  int get correctOptionIndex => _correctOptionIndex;

  /// All analogy pairs organized by difficulty tier
  static final List<_AnalogyPair> _allPairs = [
    // ─── Easy (L1-3): Concrete relationships ────────────────────────
    // Animal → Home
    _AnalogyPair('🐶', '🏠', '🐦', '🪺', '住的地方', 1),
    _AnalogyPair('🐝', '🍯', '🐦', '🪺', '住的地方', 1),
    _AnalogyPair('🐟', '🌊', '🐻', '🌲', '住的地方', 1),
    _AnalogyPair('🐰', '🕳️', '🐜', '🏔️', '住的地方', 1),

    // Animal → Sound
    _AnalogyPair('🐱', '😺', '🐶', '🐕', '叫声', 1),
    _AnalogyPair('🐮', '🐄', '🐑', '🐏', '叫声', 1),

    // Animal → Food
    _AnalogyPair('🐰', '🥕', '🐵', '🍌', '爱吃的东西', 1),
    _AnalogyPair('🐱', '🐟', '🐶', '🦴', '爱吃的东西', 1),
    _AnalogyPair('🐼', '🎋', '🐨', '🌿', '爱吃的东西', 1),

    // Weather → Protection
    _AnalogyPair('🌧️', '☔', '☀️', '🕶️', '保护', 1),
    _AnalogyPair('❄️', '🧣', '☀️', '🧢', '保护', 1),

    // Object → Use
    _AnalogyPair('✂️', '✂️📄', '🖍️', '🎨', '用来做什么', 1),
    _AnalogyPair('🪥', '🦷', '🧴', '🙌', '用来做什么', 1),

    // ─── Medium (L4-6): Part-whole, function, category ──────────────
    // Part → Whole
    _AnalogyPair('🐾', '🐱', '🦶', '👤', '是...的一部分', 4),
    _AnalogyPair('🍃', '🌳', '🪶', '🐦', '是...的一部分', 4),
    _AnalogyPair('🚪', '🏠', '📖', '📚', '是...的一部分', 4),
    _AnalogyPair('⚙️', '🤖', '🧠', '👤', '是...的一部分', 4),

    // Category membership
    _AnalogyPair('🍎', '🍉', '🚗', '🚌', '同一类', 4),
    _AnalogyPair('🐱', '🐶', '🌹', '🌻', '同一类', 4),
    _AnalogyPair('⚽', '🏀', '🎸', '🎹', '同一类', 4),

    // Function
    _AnalogyPair('🔑', '🚪', '🔌', '📱', '用来打开/启动', 4),
    _AnalogyPair('✏️', '📝', '🎤', '🎵', '用来...', 4),
    _AnalogyPair('🍳', '🍔', '🪣', '🧹', '工具和结果', 4),

    // ─── Hard (L7-8): Opposites, tools, cause-effect ────────────────
    // Opposites
    _AnalogyPair('☀️', '🌙', '🔥', '❄️', '相反', 7),
    _AnalogyPair('😊', '😢', '⬆️', '⬇️', '相反', 7),
    _AnalogyPair('🏔️', '🏖️', '🐢', '🐇', '相反', 7),

    // Tools
    _AnalogyPair('🎨', '🖌️', '📏', '📐', '工具', 7),
    _AnalogyPair('🍴', '🍝', '🥢', '🍜', '工具', 7),
    _AnalogyPair('🔨', '🔩', '🔧', '🔩', '工具', 7),

    // ─── Very Hard (L9-10): Abstract relations ──────────────────────
    // Hierarchy
    _AnalogyPair('🐱', '🐈', '🐶', '🐕', '大和小', 9),
    _AnalogyPair('🏠', '🏰', '🛶', '🚢', '小和大', 9),

    // Measurement / Quantity
    _AnalogyPair('💧', '🌊', '⭐', '🌌', '少和多', 9),
    _AnalogyPair('🕐', '🕛', '🌱', '🌳', '开始和结束', 9),

    // Transformation
    _AnalogyPair('🥚', '🐣', '🦋', '🐛', '变化', 9),
    _AnalogyPair('🌱', '🌻', '👶', '👨', '成长', 9),
  ];

  /// Pool of emoji for generating distractors
  static const List<String> _distractorPool = [
    '🍎', '🍊', '🍇', '🍓', '🍌', '🍑', '🍒', '🥝', '🍉', '🍋',
    '🐱', '🐶', '🐰', '🐻', '🐼', '🐨', '🦊', '🐸', '🐵', '🐮',
    '🚗', '🚌', '🚲', '✈️', '🚢', '🚁', '🚂', '🛵', '🏍️', '🚜',
    '🎸', '🥁', '🎹', '🎺', '🎻', '🎷', '🎵', '🔔',
    '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓',
    '🌧️', '☀️', '❄️', '🌈', '🌙', '⭐', '🔥', '💧',
    '👀', '👃', '👄', '👂', '🦶', '👋', '💪',
    '📚', '✏️', '📏', '🎒', '📐', '🖍️',
    '🌻', '🌹', '🌺', '🌸', '🌷', '💐', '🌼',
    '🍕', '🍔', '🌭', '🍟', '🍩', '🍪', '🎂',
  ];

  void nextTrial() {
    if (_isComplete) return;

    final lv = difficulty.level;
    // Filter pairs available at this level
    final available = _allPairs.where((p) => p.minLevel <= lv).toList();
    available.shuffle(_random);
    final pair = available.first;

    _emojiA = pair.a;
    _emojiB = pair.b;
    _emojiC = pair.c;
    _emojiD = pair.d;
    _relationHint = pair.hint;

    // Generate distractors (3 wrong answers)
    final distractors = _distractorPool
        .where((e) => e != _emojiD && e != _emojiA && e != _emojiB && e != _emojiC)
        .toList()
      ..shuffle(_random);

    _options = [_emojiD, ...distractors.take(3)];
    _options.shuffle(_random);
    _correctOptionIndex = _options.indexOf(_emojiD);

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  bool checkAnswer(String chosen) {
    _trialCount++;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = _options[_correctOptionIndex] == chosen;
    if (correct) _correctCount++;
    difficulty.recordResult(correct);
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reasoning_analogy',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'final_level': difficulty.level,
        'difficulty': difficulty.toJson(),
      };
}

class _AnalogyPair {
  final String a, b, c, d;
  final String hint;
  final int minLevel; // minimum difficulty level this pair appears

  const _AnalogyPair(this.a, this.b, this.c, this.d, this.hint, this.minLevel);
}
