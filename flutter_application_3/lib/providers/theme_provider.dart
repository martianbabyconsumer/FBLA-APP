import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  static const String _themeColorKey = 'theme_color';
  bool _isDarkMode = false;
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  String _selectedColor = 'Blue';

  static const Map<String, MaterialColor> _colorMap = {
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Grey': Colors.grey,
  };
  
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeProvider();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool(_themeKey) ?? false;
    _selectedColor = _prefs?.getString(_themeColorKey) ?? 'Blue';
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (!_isInitialized) return;
    
    _isDarkMode = !_isDarkMode;
    await _prefs?.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  List<String> get availableColors => _colorMap.keys.toList();

  String get selectedColorName => _selectedColor;

  Future<void> setColor(String name) async {
    if (!_isInitialized) return;
    if (!_colorMap.containsKey(name)) return;
    _selectedColor = name;
    await _prefs?.setString(_themeColorKey, _selectedColor);
    notifyListeners();
  }

  ThemeData get currentTheme {
    final color = _colorMap[_selectedColor] ?? Colors.blue;
    final brightness = _isDarkMode ? Brightness.dark : Brightness.light;
    final cs = ColorScheme.fromSwatch(primarySwatch: color, brightness: brightness).copyWith(brightness: brightness);

    // Enforce light theme background = white and make dark mode darker and cards lighter than background
    final scaffoldBg = _isDarkMode ? const Color(0xFF0B0B0D) : Colors.white;
    final cardCol = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return ThemeData.from(colorScheme: cs).copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      cardColor: cardCol,
      dividerColor: cs.primary, // use primary as outline for boxes in light mode
      appBarTheme: AppBarTheme(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: cs.onBackground),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _isDarkMode ? Colors.white : cs.primary,
        unselectedItemColor: cs.onBackground.withOpacity(0.6),
        backgroundColor: scaffoldBg,
      ),
      unselectedWidgetColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
    );
  }
}