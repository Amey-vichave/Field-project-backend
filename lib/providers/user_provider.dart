import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _userName = "John Doe";
  File? _profileImageFile; // For Mobile
  Uint8List? _profileImageBytes; // For Web

  String get userName => _userName;
  File? get profileImageFile => _profileImageFile;
  Uint8List? get profileImageBytes => _profileImageBytes;

  // 🔹 Update Name
  void updateUserName(String newName) {
    _userName = newName;
    _saveUserName(newName);
    notifyListeners();
  }

  // 🔹 Update Profile Image (Supports Web & Mobile)
  Future<void> updateProfileImage({File? imageFile, Uint8List? imageBytes}) async {
    if (kIsWeb && imageBytes != null) {
      _profileImageBytes = imageBytes;
      notifyListeners();
    } else if (!kIsWeb && imageFile != null) {
      _profileImageFile = imageFile;
      await _saveProfileImageMobile(imageFile);
      notifyListeners();
    }
  }

  // 🔹 Save Name to SharedPreferences
  Future<void> _saveUserName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
  }

  // 🔹 Save Profile Image Path (Only for Mobile)
  Future<void> _saveProfileImageMobile(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imageFile.path);
  }

  // 🔹 Load User Data on App Start
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? "John Doe";
    String? imagePath = prefs.getString('profileImagePath');

    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImageFile = File(imagePath);
    }
    notifyListeners();
  }
}
