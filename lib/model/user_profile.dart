import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile with ChangeNotifier {
  String _name = 'Unknown User';
  String _email = 'unknownuser@example.com';
  int _mealsCount = 0; // Start at 0 and load from storage
  int _favoritesCount = 0; // Start at 0 and load from storage
  String? _profileImagePath;

  String get name => _name;
  String get email => _email;
  int get mealsCount => _mealsCount;
  int get favoritesCount => _favoritesCount;
  String? get profileImagePath => _profileImagePath;

  UserProfile() {
    // Load user data from storage when the app starts
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString('user_name') ?? 'Unknown User';
    _email = prefs.getString('user_email') ?? 'unknownuser@example.com';
    _mealsCount = prefs.getInt('user_mealsCount') ?? 0;
    _favoritesCount = prefs.getInt('user_favoritesCount') ?? 0;
    _profileImagePath = prefs.getString('user_profileImagePath');
    notifyListeners();
  }

  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_email', _email);
    await prefs.setInt('user_mealsCount', _mealsCount);
    await prefs.setInt('user_favoritesCount', _favoritesCount);
    if (_profileImagePath != null) {
      await prefs.setString('user_profileImagePath', _profileImagePath!);
    }
  }

  void updateProfileImage(String? imagePath) {
    _profileImagePath = imagePath;
    _saveUserProfile();
    notifyListeners();
  }

  void incrementMeals() {
    _mealsCount++;
    _saveUserProfile(); // Save after incrementing
    notifyListeners();
  }

  void incrementFavorites() {
    _favoritesCount++;
    _saveUserProfile(); // Save after incrementing
    notifyListeners();
  }

  void decrementFavorites() {
    if (_favoritesCount > 0) {
      _favoritesCount--;
      _saveUserProfile();
      notifyListeners();
    }
  }

  void updateProfile({String? name, String? email}) {
    if (name != null && name.isNotEmpty) _name = name;
    if (email != null && email.isNotEmpty) _email = email;
    _saveUserProfile();
    notifyListeners();
  }
}