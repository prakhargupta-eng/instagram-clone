import '../constants.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return AppStrings.passwordMinLength;
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fullNameRequired;
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.usernameRequired;
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\.]+$');
    if (!usernameRegex.hasMatch(value.trim())) {
      return 'Only letters, numbers, periods, and underscores are allowed';
    }
    return null;
  }
}
