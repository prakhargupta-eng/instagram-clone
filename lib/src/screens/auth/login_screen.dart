import 'package:flutter/material.dart';
import 'package:instagram_clone/src/compontes/auth_text_field.dart';

import '../../constants.dart';
import '../../widgets/insta_logo.dart';
import '../../services/auth_service.dart';
import '../../utils/validation.dart';
import 'signup_screen.dart';
import 'package:instagram_clone/src/compontes/ToastHelper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = result.error;
    });
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    setState(() {});
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
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const InstaLogo(),
                    const SizedBox(height: 40),
                    AuthTextField(
                      controller: _emailController,
                      hintText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _clearServerError(),
                      validator: Validators.validateEmail,
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
                    const SizedBox(height: 16),
                    _buildSubmitButton(),
                    const SizedBox(height: 18),
                    _buildOrDivider(),
                    const SizedBox(height: 18),
                    _buildFacebookButton(),
                    const SizedBox(height: 30),
                    _buildSignUpLink(),
                    const SizedBox(height: 24),
                    _buildDemoAccounts(),
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
  Widget _buildSubmitButton() {
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
            : const Text(AppStrings.logIn),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppStrings.or,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildFacebookButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => ToastHelper.showToast(context, AppStrings.facebookLoginMock),
          icon: const Icon(
            Icons.facebook,
            color: AppColors.primaryDark,
            size: 22,
          ),
          label: const Text(
            AppStrings.logInWithFacebook,
            style: TextStyle(color: AppColors.primaryDark),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          AppStrings.dontHaveAccount,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SignupScreen(authService: widget.authService),
            ),
          ),
          child: const Text(AppStrings.signUp),
        ),
      ],
    );
  }

  Widget _buildDemoAccounts() {
    return Column(
      children: [
        const Text(
          AppStrings.demoAccounts,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: const [
            _DemoChip(label: 'alice@example.com'),
            _DemoChip(label: 'marco@example.com'),
            _DemoChip(label: 'priya@example.com'),
          ],
        ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>();
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
      onPressed: () => state?._fillDemo(label),
    );
  }
}
