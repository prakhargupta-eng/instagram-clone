import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';
import 'package:instagram_clone/src/components/auth_text_field.dart';
import 'package:instagram_clone/src/utils/validation.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';
import 'package:instagram_clone/src/components/ToastHelper.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ToastHelper.showToast(
        context,
        'Passwords do not match.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    final result = await widget.authService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ToastHelper.showToast(context, "Password updated successfully.");
      Navigator.of(context).pop();
    } else {
      ToastHelper.showToast(
        context,
        'Failed to update password: ${result.error}',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.surfaceColor,

        appBar: AppBar(title: const Text('Change Password')),

        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Your fields
              _PasswordField(
                controller: _oldPasswordController,
                labelText: 'Current Password',
                validator: Validators.validatePassword,
              ),

              const SizedBox(height: 16),

              _PasswordField(
                controller: _newPasswordController,
                labelText: 'New Password',
                validator: Validators.validatePassword,
              ),

              const SizedBox(height: 16),

              _PasswordField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ),

        // 👇 Fixed bottom button
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(
                  _saving ? 'Saving...' : AppStrings.done,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 23, 24, 24),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.labelText,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            widget.labelText,
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        AuthTextField(
          controller: widget.controller,
          hintText: widget.labelText,
          obscureText: _obscure,
          validator: widget.validator,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ],
    );
  }
}
