import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile with ChangeNotifier {
  String _name = 'Unknown User';
  String _email = 'Unknown Email';

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

  void initializeFromFirebaseAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _name = user.displayName ?? 'Unknown User';
      _email = user.email ?? 'Unknown Email';
      notifyListeners();
    }
  }
}
