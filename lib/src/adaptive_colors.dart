import 'package:flutter/material.dart';
import 'app.dart';
import 'constants.dart';

/// BuildContext extension for theme-aware colors.
///
/// Usage: `context.textPrimaryColor`, `context.surfaceColor`, etc.
/// Automatically picks light or dark color based on the current theme.
extension AdaptiveColors on BuildContext {
  bool get _dark => isDark(this);

  Color get textPrimaryColor =>
      _dark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondaryColor =>
      _dark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get surfaceColor => _dark ? AppColors.darkSurface : AppColors.surface;

  Color get backgroundColor =>
      _dark ? AppColors.darkBackground : AppColors.background;

  Color get borderColor => _dark ? AppColors.border : AppColors.darkBorder;

  Color get primaryColor => _dark ? AppColors.primaryDark : AppColors.primary;
}
