import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../widgets/avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  late String _avatarUrl;
  bool _saving = false;

  static const _avatarOptions = [
    'https://i.pravatar.cc/300?img=5',
    'https://i.pravatar.cc/300?img=8',
    'https://i.pravatar.cc/300?img=11',
    'https://i.pravatar.cc/300?img=13',
    'https://i.pravatar.cc/300?img=16',
    'https://i.pravatar.cc/300?img=31',
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _bioController = TextEditingController(text: widget.user.bio);
    _avatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _save() {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    if (username.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.fillAllFields)),
      );
      return;
    }
    setState(() => _saving = true);
    widget.authService.updateCurrentUser(
      widget.user.copyWith(
        username: username,
        fullName: fullName,
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrl,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving...' : AppStrings.done,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              children: [
                Avatar(url: _avatarUrl, radius: 42),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                    ),
                    child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Change avatar',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final url in [..._avatarOptions, _avatarUrl])
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _avatarUrl = url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: url == _avatarUrl ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Avatar(url: url, radius: 22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _field(label: AppStrings.username, controller: _usernameController),
          const SizedBox(height: 16),
          _field(label: AppStrings.fullName, controller: _fullNameController),
          const SizedBox(height: 16),
          _field(label: 'Bio', controller: _bioController, maxLines: 3),
          const SizedBox(height: 8),
          const Text(
            'Swipe across avatars or pick one above.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
