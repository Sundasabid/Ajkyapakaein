import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel with ChangeNotifier {
  bool _notifications = true;
  bool _darkMode = false;
  String _language = 'English';

  bool get notifications => _notifications;
  bool get darkMode => _darkMode;
  String get language => _language;

  SettingsModel() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _notifications = prefs.getBool('settings_notifications') ?? true;
    _darkMode = prefs.getBool('settings_darkMode') ?? false;
    _language = prefs.getString('settings_language') ?? 'English';
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications', _notifications);
    await prefs.setBool('settings_darkMode', _darkMode);
    await prefs.setString('settings_language', _language);
  }

  void setNotifications(bool value) {
    _notifications = value;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleNotifications() => setNotifications(!_notifications);

  void setDarkMode(bool value) {
    _darkMode = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setLanguage(String newLanguage) {
    _language = newLanguage;
    _saveToPrefs();
    notifyListeners();
  }

  /// Placeholder for account deletion logic.
  /// Replace with Firebase / backend deletion steps as needed.
  Future<void> deleteAccountPlaceholder() async {
    // Reset settings locally
    _notifications = true;
    _darkMode = false;
    _language = 'English';
    await _saveToPrefs();
    notifyListeners();
  }
}
