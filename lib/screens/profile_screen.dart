// Uint8List for web images
import 'dart:io'; // File for mobile images
import 'package:flutter/foundation.dart'; // kIsWeb check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _imageFile; // For mobile
  Uint8List? _imageBytes; // For web
  double _fontSize = 16;

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    var userProvider = Provider.of<UserProvider>(context);
    _nameController.text = userProvider.userName; // Pre-fill with user’s name

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePictureSection(),
            SizedBox(height: 20),
            _buildUserInfo(userProvider),
            SizedBox(height: 20),
            _buildSettings(themeProvider, userProvider),
            SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  /// 🖼️ **Profile Picture Section**
  Widget _buildProfilePictureSection() {
    var userProvider = Provider.of<UserProvider>(context);

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: kIsWeb
                ? (userProvider.profileImageBytes != null
                    ? MemoryImage(userProvider.profileImageBytes!)
                    : null)
                : (userProvider.profileImageFile != null
                    ? FileImage(userProvider.profileImageFile!)
                    : null),
            child: (userProvider.profileImageBytes == null &&
                    userProvider.profileImageFile == null)
                ? Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          SizedBox(height: 10),
          TextButton.icon(
            onPressed: _pickImage,
            icon: Icon(Icons.camera_alt, color: Colors.green),
            label: Text("Change Profile Picture",
                style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  /// ℹ️ **User Information**
  Widget _buildUserInfo(UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Full Name",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
              border: OutlineInputBorder(), hintText: "Enter new name"),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            userProvider.updateUserName(_nameController.text.trim());
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Name updated!")));
          },
          child: Text("Update Name"),
        ),
        SizedBox(height: 20),
        Divider(),
        ListTile(
          leading: Icon(Icons.email, color: Colors.green),
          title: Text("Email"),
          subtitle: Text("user@example.com"),
        ),
        ListTile(
          leading: Icon(Icons.security, color: Colors.green),
          title: Text("Role"),
          subtitle: Text("Pharmacist"),
        ),
        ListTile(
          leading: Icon(Icons.date_range, color: Colors.green),
          title: Text("Joined On"),
          subtitle: Text("January 2024"),
        ),
        Divider(),
      ],
    );
  }

  /// ⚙️ **Settings: Theme, Font Size, Security**
  Widget _buildSettings(
      ThemeProvider themeProvider, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Preferences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: Text("Dark Mode"),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
          },
        ),
        ListTile(
          title: Text("Font Size"),
          subtitle: Slider(
            value: _fontSize,
            min: 14,
            max: 22,
            divisions: 4,
            label: "${_fontSize.toInt()}",
            onChanged: (value) {
              setState(() {
                _fontSize = value;
              });
            },
          ),
        ),
        Divider(),
        Text("Security",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ListTile(
          leading: Icon(Icons.lock, color: Colors.green),
          title: Text("Change Password"),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Feature Coming Soon!")));
          },
        ),
        ListTile(
          leading: Icon(Icons.fingerprint, color: Colors.green),
          title: Text("Enable PIN Lock"),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Feature Coming Soon!")));
          },
        ),
        Divider(),
      ],
    );
  }

  /// 🔴 **Logout Button**
  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () => _confirmLogout(context),
        icon: Icon(Icons.exit_to_app),
        label: Text("Logout"),
      ),
    );
  }

  /// 📸 **Image Picker (Supports Web & Mobile)**
  Future<void> _pickImage() async {
    var userProvider = Provider.of<UserProvider>(context, listen: false);

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // Convert to Uint8List for web
        var bytes = await pickedFile.readAsBytes();
        userProvider.updateProfileImage(imageBytes: bytes);
      } else {
        // Use File for mobile
        userProvider.updateProfileImage(imageFile: File(pickedFile.path));
      }
    }
  }

  /// 🚪 **Logout Confirmation Dialog**
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignupScreen()),
                  (route) => false);
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
