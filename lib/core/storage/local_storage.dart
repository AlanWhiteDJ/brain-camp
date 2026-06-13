import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorage {
  static const _keyProfile = 'child_profile';
  static const _keyTrainingHistory = 'training_history';
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Child profile
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _prefs.setString(_keyProfile, jsonEncode(profile));
  }

  static Map<String, dynamic>? loadProfile() {
    final s = _prefs.getString(_keyProfile);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static bool get hasProfile => _prefs.containsKey(_keyProfile);

  // Training history
  static Future<void> saveTrainingSession(Map<String, dynamic> session) async {
    final history = loadTrainingHistory();
    history.add(session);
    // Keep only last 200 sessions
    if (history.length > 200) history.removeAt(0);
    await _prefs.setString(_keyTrainingHistory, jsonEncode(history));
  }

  static List<Map<String, dynamic>> loadTrainingHistory() {
    final s = _prefs.getString(_keyTrainingHistory);
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  static List<Map<String, dynamic>> getSessionsForTask(String taskId) {
    return loadTrainingHistory()
        .where((s) => s['task_id'] == taskId)
        .toList();
  }

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
