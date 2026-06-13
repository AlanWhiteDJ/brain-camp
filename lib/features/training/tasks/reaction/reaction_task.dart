import 'dart:math';
class ReactionTask {
  final int childAge;
  final Random _random = Random();

  static const int maxTrials = 30;
  static const int anticipationMinMs = 100; // below this = too early

  // State
  int _trialCount = 0;
  bool _isComplete = false;

  // Trial phases
  ReactionPhase _phase = ReactionPhase.waiting;
  int _foreperiodMs = 0;
  int _stimulusOnMs = 0;

  // Metrics
  final List<int> _reactionTimes = [];
  int _anticipations = 0;

  int get foreperiodMs => _foreperiodMs;

  ReactionTask({required this.childAge});

  // Getters
  ReactionPhase get phase => _phase;
  int get trialCount => _trialCount;
  bool get isComplete => _isComplete;
  List<int> get reactionTimes => List.unmodifiable(_reactionTimes);
  int get anticipations => _anticipations;
  double get progress => _trialCount / maxTrials;

  double get meanReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  double get medianReactionTime {
    if (_reactionTimes.isEmpty) return 0;
    final sorted = List.of(_reactionTimes)..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[mid].toDouble() : (sorted[mid - 1] + sorted[mid]) / 2.0;
  }

  /// Start a trial: begin waiting phase
  void startTrial() {
    if (_isComplete) return;
    _phase = ReactionPhase.waiting;
    _foreperiodMs = 1500 + _random.nextInt(2500); // 1.5-4s random wait
  }

  /// Called by timer when foreperiod ends
  void showStimulus() {
    if (_phase != ReactionPhase.waiting) return;
    _phase = ReactionPhase.stimulus;
    _stimulusOnMs = DateTime.now().millisecondsSinceEpoch;
  }

  /// Called when user taps
  ReactionResult tap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_phase == ReactionPhase.waiting) {
      // Tapped too early!
      _phase = ReactionPhase.feedback;
      return ReactionResult.early;
    }

    if (_phase == ReactionPhase.stimulus) {
      final rt = now - _stimulusOnMs;
      _phase = ReactionPhase.feedback;

      if (rt < anticipationMinMs) {
        _anticipations++;
        return ReactionResult.anticipation;
      }

      _reactionTimes.add(rt);
      _trialCount++;
      if (_trialCount >= maxTrials) _isComplete = true;
      return ReactionResult.hit;
    }

    // Already in feedback phase
    return ReactionResult.none;
  }

  Map<String, dynamic> toSessionData() => {
        'task_id': 'reaction',
        'timestamp': DateTime.now().toIso8601String(),
        'total_trials': _trialCount,
        'mean_rt': meanReactionTime,
        'median_rt': medianReactionTime,
        'anticipations': _anticipations,
        'reaction_times': _reactionTimes,
        'child_age': childAge,
      };
}

enum ReactionPhase { waiting, stimulus, feedback }

enum ReactionResult { hit, early, anticipation, none }
