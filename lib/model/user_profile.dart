import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile with ChangeNotifier {
  String _name = 'Unknown User';
  String _email = 'unknownuser@example.com';

  int _mealsCount = 0;
  String? _profileImagePath;

  String get name => _name;
  String get email => _email;
  int get mealsCount => _mealsCount;
  String? get profileImagePath => _profileImagePath;

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  void updateProfileImage(String? imagePath) {
    _profileImagePath = imagePath;
    notifyListeners();
  }

  void incrementMeals() {
    _mealsCount++;
    notifyListeners();
  }

  void updateProfile({String? name, String? email}) {
    if (name != null) _name = name;
    if (email != null) _email = email;
    notifyListeners();
  }

  // Initialize profile with Firebase Auth data
  void initializeFromFirebaseAuth() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use displayName if available, otherwise fallback to email without domain
      _name = user.displayName ?? _extractNameFromEmail(user.email ?? '');
      _email = user.email ?? 'Unknown Email';
      notifyListeners();
    }
  }

  // Helper method to extract name from email
  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return 'Unknown User';
    // Extract the part before @ and capitalize it
    String name = email.split('@')[0];
    return name.split('.').map((part) => 
      part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1).toLowerCase()
    ).join(' ');
  }

  // Update profile from Firebase Auth changes
  void updateFromFirebaseAuth() {
    initializeFromFirebaseAuth();
  }
}
