import 'package:flutter/material.dart';
import 'package:toko_game/utils/database_helper.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final DatabaseHelper _dbHelper;

  ThemeProvider({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  // Add isDarkMode getter for UI
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadThemeMode() async {
    try {
      final settings = await _dbHelper.getSettings();
      final themeModeValue = settings['theme_mode'];

      // Always convert to string first
      final themeModeStr = themeModeValue?.toString() ?? 'system';

      switch (themeModeStr) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Convert to string before saving to ensure type consistency
    String themeModeStr;
    switch (mode) {
      case ThemeMode.light:
        themeModeStr = 'light';
        break;
      case ThemeMode.dark:
        themeModeStr = 'dark';
        break;
      default:
        themeModeStr = 'system';
    }

    try {
      await _dbHelper.updateSettings({'theme_mode': themeModeStr});
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  // Add toggleTheme method for UI convenience
  void toggleTheme() {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}
