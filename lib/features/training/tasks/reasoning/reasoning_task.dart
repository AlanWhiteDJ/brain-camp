import 'dart:math';

/// Pattern Reasoning Task
/// Pattern completion: "What comes next?"
/// Simple sequences for kids: ABAB, AABB, ABCABC, etc.

class ReasoningTask {
  final int childAge;
  final Random _random = Random();

  static const int totalTrials = 20;

  // State
  int _trialCount = 0;
  int _correctCount = 0;
  bool _isComplete = false;
  final List<int> _reactionTimes = [];
  int _trialStartMs = 0;

  // Current pattern
  late PatternType _currentType;
  late List<String> _sequence;
  late List<String> _options;
  late String _correctAnswer;
  late int _correctOptionIndex;

  int get correctOptionIndex => _correctOptionIndex;
  String get correctAnswer => _correctAnswer;

  ReasoningTask({required this.childAge});

  // Getters
  int get trialCount => _trialCount;
  int get correctCount => _correctCount;
  bool get isComplete => _isComplete;
  double get accuracy => _trialCount > 0 ? _correctCount / _trialCount : 0;
  double get progress => _trialCount / totalTrials;
  List<String> get sequence => List.unmodifiable(_sequence);
  List<String> get options => List.unmodifiable(_options);

  void nextTrial() {
    if (_isComplete) return;

    // Pick pattern type based on age
    final types = childAge <= 5 ? [PatternType.ab, PatternType.aabb] :
                 childAge <= 7 ? [PatternType.ab, PatternType.aabb, PatternType.abc] :
                 [PatternType.ab, PatternType.aabb, PatternType.abc, PatternType.abb, PatternType.aba];

    _currentType = types[_random.nextInt(types.length)];

    // Generate sequence
    switch (_currentType) {
      case PatternType.ab:
        _generateAB();
        break;
      case PatternType.aabb:
        _generateAABB();
        break;
      case PatternType.abc:
        _generateABC();
        break;
      case PatternType.abb:
        _generateABB();
        break;
      case PatternType.aba:
        _generateABA();
        break;
    }

    // Generate options (1 correct + 3 wrong)
    final base = _getBaseItems();
    final wrong = base.where((e) => e != _correctAnswer).toList()..shuffle(_random);
    final allOptions = [_correctAnswer, ...wrong.take(3)];
    allOptions.shuffle(_random);
    _options = allOptions;
    _correctOptionIndex = _options.indexOf(_correctAnswer);

    _trialStartMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _generateAB() {
    final items = _pick(2);
    _sequence = [items[0], items[1], items[0], items[1], '❓'];
    _correctAnswer = items[1];
  }

  void _generateAABB() {
    final items = _pick(2);
    _sequence = [items[0], items[0], items[1], items[1], '❓'];
    _correctAnswer = items[0];
  }

  void _generateABC() {
    final items = _pick(3);
    _sequence = [items[0], items[1], items[2], items[0], '❓'];
    _correctAnswer = items[1];
  }

  void _generateABB() {
    final items = _pick(2);
    _sequence = [items[0], items[1], items[1], '❓', ''];
    _correctAnswer = items[0];
  }

  void _generateABA() {
    final items = _pick(2);
    _sequence = [items[0], items[1], items[0], '❓', ''];
    _correctAnswer = items[0];
  }

  List<String> _pick(int n) {
    final pool = _getBaseItems()..shuffle(_random);
    return pool.take(n).toList();
  }

  List<String> _getBaseItems() => ['🍎', '⭐', '🌙', '🌸', '🎈', '🐱'];

  bool checkAnswer(String chosen) {
    _trialCount++;
    final rt = DateTime.now().millisecondsSinceEpoch - _trialStartMs;
    _reactionTimes.add(rt);

    final correct = _options[_correctOptionIndex] == chosen;
    if (correct) _correctCount++;
    if (_trialCount >= totalTrials) _isComplete = true;
    return correct;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reasoning',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'correct_count': _correctCount,
        'accuracy': accuracy,
        'child_age': childAge,
      };
}

enum PatternType { ab, aabb, abc, abb, aba }
