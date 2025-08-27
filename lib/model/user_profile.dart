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

  // Load user data from Firebase Auth
  void loadUserFromFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _name = user.displayName ?? 'Unknown User';
      _email = user.email ?? 'Unknown Email';
      notifyListeners();
    }
  }

  // Update Firebase user and local state
  Future<void> updateFirebaseProfile({String? name, String? email}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && name != null) {
      try {
        await user.updateDisplayName(name);
        await user.reload();
        loadUserFromFirebase(); // Refresh local data
      } catch (e) {
        print('Error updating Firebase profile: $e');
      }
    }
    // Update local data as well
    updateProfile(name: name, email: email);
  }
}
