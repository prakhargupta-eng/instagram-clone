import 'package:flutter/material.dart';
import '../../../adaptive_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instagram_clone/src/compontes/auth_text_field.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../constants.dart';
import '../../../widgets/insta_logo.dart';
import '../../../services/auth_service.dart';
import '../../../utils/validation.dart';
import 'package:instagram_clone/src/compontes/ToastHelper.dart';
import 'signup_view_model.dart';

import '../../home/home_shell.dart';

/// Signup screen — pure View layer.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SignupViewModel? _vmInstance;
  SignupViewModel get _vm => _vmInstance!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vmInstance ??= SignupViewModel(
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
    if (mounted) {
      if (error != null) {
        ToastHelper.showToast(context, error, isError: true);
      } else {
        ToastHelper.showToast(context, 'Account created successfully!');
        FocusScope.of(context).unfocus();
        
        // Explicitly clear the navigation stack and push HomeShell
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeShell(authService: widget.authService),
          ),
          (route) => false,
        );
      }
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
                    key: _vm.formKey,
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
                          controller: _vm.emailController,
                          hintText: AppStrings.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _vm.fullNameController,
                          hintText: AppStrings.fullName,
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _vm.usernameController,
                          hintText: AppStrings.username,
                          validator: Validators.validateUsername,
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _vm.passwordController,
                          hintText: AppStrings.password,
                          obscureText: _vm.obscurePassword,
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
      },
    );
  }

  Widget _buildSignUpButton() {
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
