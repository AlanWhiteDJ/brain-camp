import 'package:flutter/material.dart';
import '../../core/storage/local_storage.dart';

class ChildProfileState extends ChangeNotifier {
  String _nickname = '';
  int _age = 6;
  String _gender = 'boy';
  String _avatar = '🧒';

  String get nickname => _nickname;
  int get age => _age;
  String get gender => _gender;
  String get avatar => _avatar;

  bool get hasProfile => _nickname.isNotEmpty;

  static const _avatars = ['🧒', '👦', '👧', '🐶', '🐱', '🐰', '🦊', '🐼'];

  void load(Map<String, dynamic> data) {
    _nickname = data['nickname'] ?? '';
    _age = data['age'] ?? 6;
    _gender = data['gender'] ?? 'boy';
    _avatar = data['avatar'] ?? '🧒';
    notifyListeners();
  }

  void updateNickname(String name) {
    _nickname = name;
    notifyListeners();
  }

  void updateAge(int age) {
    _age = age.clamp(3, 12);
    notifyListeners();
  }

  void updateGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void updateAvatar(String avatar) {
    _avatar = avatar;
    notifyListeners();
  }

  Future<void> save() async {
    await LocalStorage.saveProfile({
      'nickname': _nickname,
      'age': _age,
      'gender': _gender,
      'avatar': _avatar,
    });
  }

  Map<String, dynamic> toJson() => {
        'nickname': _nickname,
        'age': _age,
        'gender': _gender,
        'avatar': _avatar,
      };

  static List<String> get avatarOptions => _avatars;
}
