import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final String _themeModeKey = 'theme_mode';

  ThemeProvider() {
    _loadThemeMode();
  }

  // Getter
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Load theme từ SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);

    if (savedThemeMode != null) {
      _themeMode = savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }

  // Lưu theme vào SharedPreferences
  Future<void> _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  // Chuyển đổi theme
  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode();
    notifyListeners();
  }

  // Set theme cụ thể
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFFF6F61), // Coral
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFF333333),
          fontSize: 50,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
        bodyMedium: TextStyle(color: Color(0xFF333333)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF40C4FF), // Sky Blue
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF40C4FF)),
          foregroundColor: const Color(0xFF40C4FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF6F61),
        secondary: Color.fromARGB(255, 135, 44, 255),
        error: Colors.red,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color.fromARGB(255, 234, 0, 255), // Neon Green
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark Background
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Color(0xFFE0E0E0),
          fontSize: 50,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
        bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE040FB), // Neon Purple
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE040FB)),
          foregroundColor: const Color(0xFFE040FB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      cardColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 135, 44, 255),
        secondary: Color(0xFFE040FB),
        error: Colors.redAccent,
      ),
    );
  }
}
