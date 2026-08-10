import 'package:flutter/material.dart';
import 'package:instagram_clone/src/compontes/auth_text_field.dart';

import '../../constants.dart';
import '../../widgets/insta_logo.dart';
import '../../services/auth_service.dart';
import '../../utils/validation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.authService.signup(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (result.success) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _loading = false;
      _error = result.error;
    });
  }

  void _clearServerError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const InstaLogo(size: 56, withIcon: false),
                    const SizedBox(height: 6),
                    const Text(
                      AppStrings.signupTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _emailController,
                      hintText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _clearServerError(),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      controller: _fullNameController,
                      hintText: AppStrings.fullName,
                      onChanged: (_) => _clearServerError(),
                      validator: Validators.validateFullName,
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      controller: _usernameController,
                      hintText: AppStrings.username,
                      onChanged: (_) => _clearServerError(),
                      validator: Validators.validateUsername,
                    ),
                    const SizedBox(height: 10),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: AppStrings.password,
                      obscureText: _obscure,
                      onChanged: (_) => _clearServerError(),
                      validator: Validators.validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildSignUpButton(),
                    const SizedBox(height: 20),
                    _buildAgreementText(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSignUpButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Text(AppStrings.signUp),
      ),
    );
  }

  Widget _buildAgreementText() {
    return const Text(
      AppStrings.signupAgreement,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );
  }
}
