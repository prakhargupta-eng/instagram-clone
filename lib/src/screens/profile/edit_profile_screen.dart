import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instagram_clone/src/components/ToastHelper.dart';
import 'package:instagram_clone/src/utils/validation.dart';

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
  late final TextEditingController _websiteController;
  late final TextEditingController _genderController;
  late String _avatarUrl;
  late String _gender;
  late bool _isPrivate;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _pickAvatarFromGallery() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _avatarUrl = picked.path);
    } catch (e) {
      debugPrint('Error picking avatar: $e');
      if (mounted) {
        ToastHelper.showToast(
          context,
          'Failed to pick avatar image: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print("🔥 EditProfileScreen initState - User: ${widget.user}");
    _usernameController = TextEditingController(text: widget.user.username);
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _bioController = TextEditingController(text: widget.user.bio);
    _websiteController = TextEditingController(text: widget.user.website);
    _gender = widget.user.gender;
    _genderController = TextEditingController(
      text: _gender.isEmpty ? 'Not specified' : _gender,
    );
    _avatarUrl = widget.user.avatarUrl;
    _isPrivate = widget.user.isPrivate;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    widget.authService.updateCurrentUser(
      widget.user.copyWith(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrl,
        website: _websiteController.text.trim(),
        gender: _gender,
        isPrivate: _isPrivate,
      ),
    );
    ToastHelper.showToast(context, 'Profile updated successfully.');
    Navigator.of(context).pop();
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        final options = ['Male', 'Female', 'Prefer not to say'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
               Text(
                'Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              const Divider(height: 24),
              for (final option in options)
                ListTile(
                  title: Text(
                    option,
                    style: TextStyle(color: context.textPrimaryColor),
                  ),
                  onTap: () {
                    setState(() {
                      _gender = option;
                      _genderController.text = option;
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.surfaceColor,
        appBar: AppBar(
          title: const Text(
            'Edit profile',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? 'Saving...' : AppStrings.done,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Avatar(url: _avatarUrl, radius: 42),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickAvatarFromGallery,
                      child: const Text(
                        'Edit picture or avatar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _rowField(
                label: 'Name',
                controller: _fullNameController,
                hintText: 'Enter name',
                validator: Validators.validateFullName,
              ),
              _rowField(
                label: 'Username',
                controller: _usernameController,
                hintText: 'Enter username',
                validator: Validators.validateUsername,
              ),
              _rowField(
                label: 'Website',
                controller: _websiteController,
                hintText: 'Add link',
              ),
              _rowField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
                hintText: 'Enter bio ',
              ),
              _buildPrivateSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration:  BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style:  TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimaryColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
              style:  TextStyle(
                fontSize: 15,
                color: context.textPrimaryColor,
              ),
              validator: validator,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:  TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
         Text(
          'Private Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _rowField(
          label: 'Gender',
          controller: _genderController,
          readOnly: true,
          onTap: _showGenderPicker,
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration:  BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.borderColor, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Private Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimaryColor,
                ),
              ),
              Switch.adaptive(
                value: _isPrivate,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _isPrivate = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
