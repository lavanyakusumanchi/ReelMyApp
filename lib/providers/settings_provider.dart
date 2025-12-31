import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  
  // State
  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');
  bool _autoScrollEnabled = false;
  bool _notificationsEnabled = true;
  bool _dataSaver = false;
  String _downloadQuality = 'High';

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get autoScrollEnabled => _autoScrollEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get dataSaver => _dataSaver;
  String get downloadQuality => _downloadQuality;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = _prefs?.getBool('isDarkMode') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Locale
    final langCode = _prefs?.getString('languageCode') ?? 'en';
    _locale = Locale(langCode);

    // Load AutoScroll
    _autoScrollEnabled = _prefs?.getBool('autoScroll') ?? false;

    // Load Notifications
    _notificationsEnabled = _prefs?.getBool('notifications') ?? true;

    // Load Data Saver
    _dataSaver = _prefs?.getBool('dataSaver') ?? false;

    // Load Download Quality
    _downloadQuality = _prefs?.getString('downloadQuality') ?? 'High';

    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _prefs?.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await _prefs?.setString('languageCode', languageCode);
    notifyListeners();
  }

  Future<void> toggleAutoScroll(bool enabled) async {
    _autoScrollEnabled = enabled;
    await _prefs?.setBool('autoScroll', enabled);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs?.setBool('notifications', enabled);
    notifyListeners();
  }

  Future<void> toggleDataSaver(bool enabled) async {
    _dataSaver = enabled;
    await _prefs?.setBool('dataSaver', enabled);
    notifyListeners();
  }

  Future<void> setDownloadQuality(String quality) async {
    _downloadQuality = quality;
    await _prefs?.setString('downloadQuality', quality);
    notifyListeners();
  }
}
