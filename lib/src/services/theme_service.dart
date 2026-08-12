import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _kThemeModeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Fallback/Default to system brightness if system is selected.
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeService() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModeIndex = prefs.getInt(_kThemeModeKey);
      if (savedModeIndex != null) {
        _themeMode = ThemeMode.values[savedModeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kThemeModeKey, mode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await updateThemeMode(nextMode);
  }
}
