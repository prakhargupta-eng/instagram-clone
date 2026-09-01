import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instagram_clone/src/components/auth_text_field.dart';

import '../../../blocs/auth/auth_bloc.dart';

import '../../../constants.dart';
import '../../../widgets/insta_logo.dart';
import '../../../services/auth_service.dart';
import '../../../utils/validation.dart';
import '../signup/signup_screen.dart';
import 'package:instagram_clone/src/components/ToastHelper.dart';
import 'login_view_model.dart';

/// Login screen — pure View layer.
///
/// All state and business logic is delegated to [LoginViewModel].
/// This widget only builds UI and forwards user interactions to the ViewModel.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewModel? _vmInstance;
  LoginViewModel get _vm => _vmInstance!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Inject AuthBloc and AuthService on first build
    _vmInstance ??= LoginViewModel(
      authBloc: context.read<AuthBloc>(),
      authService: widget.authService,
    );
  }

  @override
  void dispose() {
    _vmInstance?.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final error = await _vm.submit();
    if (error != null && mounted) {
      ToastHelper.showToast(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: context.surfaceColor,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _vm.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        const InstaLogo(),
                        const SizedBox(height: 40),

                        // Email field
                        AuthTextField(
                          controller: _vm.emailController,
                          hintText: AppStrings.email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => _vm.clearServerError(),
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 10),

                        // Password field
                        AuthTextField(
                          controller: _vm.passwordController,
                          hintText: AppStrings.password,
                          obscureText: _vm.obscurePassword,
                          onChanged: (_) => _vm.clearServerError(),
                          validator: Validators.validatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _vm.obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: _vm.toggleObscure,
                          ),
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),

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
      },
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: _vm.isLoading ? null : _handleSubmit,
        child: _vm.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.surfaceColor,
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
          onPressed: () =>
              ToastHelper.showToast(context, AppStrings.facebookLoginMock),
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
          children: [
            _DemoChip(label: 'alice@example.com', onTap: _vm.fillDemo),
            _DemoChip(label: 'marco@example.com', onTap: _vm.fillDemo),
            _DemoChip(label: 'priya@example.com', onTap: _vm.fillDemo),
          ],
        ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
      onPressed: () => onTap(label),
    );
  }
}
