import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import 'child_profile.dart';

class ProfileScreen extends StatefulWidget {
  final bool isFirstTime;
  const ProfileScreen({super.key, this.isFirstTime = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameController = TextEditingController();
  int _age = 6;
  String _gender = 'boy';
  String _selectedAvatar = '🧒';

  @override
  void initState() {
    super.initState();
    final state = context.read<ChildProfileState>();
    if (state.hasProfile) {
      _nicknameController.text = state.nickname;
      _age = state.age;
      _gender = state.gender;
      _selectedAvatar = state.avatar;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: widget.isFirstTime
          ? null
          : AppBar(
              title: const Text('孩子档案'),
              backgroundColor: Colors.transparent,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isFirstTime) ...[
                const SizedBox(height: 40),
                const Center(
                  child: Text('🧠', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    '欢迎来到 Brain Camp！',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '先给宝贝建个档案吧',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Avatar picker
              const Text('选个头像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ChildProfileState.avatarOptions.map((a) {
                  final selected = _selectedAvatar == a;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = a),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(color: AppTheme.primaryGreen, width: 2)
                            : Border.all(color: Colors.grey[200]!),
                      ),
                      child: Center(
                        child: Text(a, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Nickname
              const Text('宝贝昵称', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  hintText: '比如：小乐、豆豆',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Age
              const Text('年龄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _age > 3 ? () => setState(() => _age--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_age 岁',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _age < 12 ? () => setState(() => _age++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gender
              const Text('性别', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _GenderButton(
                      label: '👦 男孩',
                      selected: _gender == 'boy',
                      onTap: () => setState(() => _gender = 'boy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderButton(
                      label: '👧 女孩',
                      selected: _gender == 'girl',
                      onTap: () => setState(() => _gender = 'girl'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nicknameController.text.trim().isEmpty
                      ? null
                      : () async {
                          final state = context.read<ChildProfileState>();
                          state
                            ..updateNickname(_nicknameController.text.trim())
                            ..updateAge(_age)
                            ..updateGender(_gender)
                            ..updateAvatar(_selectedAvatar);
                          await state.save();

                          if (mounted) {
                            if (widget.isFirstTime) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            } else {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                  child: Text(
                    widget.isFirstTime ? '开始训练 ▶' : '保存',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: AppTheme.primaryGreen, width: 2)
              : Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}


