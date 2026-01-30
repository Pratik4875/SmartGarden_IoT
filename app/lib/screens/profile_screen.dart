import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ota_update/ota_update.dart'; // Import is now used
import '../services/iot_service.dart';
import '../widgets/custom_loading_animation.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final IoTService iotService;
  const ProfileScreen({super.key, required this.iotService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    String name = widget.iotService.userName;
    String? photo = widget.iotService.photoUrl;

    // Auto-fill from Google if available
    final user = widget.iotService.firebaseAuth.currentUser;
    if (user != null) {
      if ((name == "Student" || name == "User" || name.isEmpty) &&
          user.displayName != null) {
        name = user.displayName!;
        widget.iotService.updateProfileName(name);
      }
      if (photo == null && user.photoURL != null) {
        photo = user.photoURL;
        widget.iotService.updateProfilePhoto(photo!);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    String savedUrl = prefs.getString('firebase_url') ?? "";

    if (mounted) {
      setState(() {
        _nameController.text = name;
        _urlController.text = savedUrl;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _saveSettings() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);

    await widget.iotService.updateProfileName(_nameController.text.trim());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_url', _urlController.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated! Restarting...")),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _logout() async {
    await widget.iotService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _runUpdate() async {
    // 1. Show Checking Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Row(
          children: [
            const CustomLoadingAnimation(size: 30),
            const SizedBox(width: 20),
            Text(
              "Checking for updates...",
              style: GoogleFonts.robotoMono(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    // 2. Perform Check
    final result = await widget.iotService.checkForUpdate();
    if (!mounted) return;
    Navigator.pop(context); // Close "Checking..."

    bool available = result['updateAvailable'] ?? false;
    String version = result['latestVersion'] ?? "Unk";
    String? downloadUrl = result['downloadUrl'];

    if (!available) {
      // 3A. No Update
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App is up to date!")),
      );
    } else if (downloadUrl != null) {
      // 3B. Update Available -> Ask User
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text("UPDATE AVAILABLE ($version)", style: const TextStyle(color: Colors.cyanAccent)),
          content: Text("A new version is available. Download now?", style: GoogleFonts.robotoMono(color: Colors.white70)),
          actions: [
            TextButton(
               onPressed: () => Navigator.pop(context),
               child: const Text("LATER"),
            ),
            TextButton(
               onPressed: () {
                 Navigator.pop(context);
                 _startDownload(downloadUrl);
               },
               child: const Text("UPDATE", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      );
    }
  }

  void _startDownload(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "DOWNLOADING...",
          style: GoogleFonts.robotoMono(color: Colors.cyanAccent),
        ),
        content: SizedBox(
          height: 100,
          child: StreamBuilder<OtaEvent>(
            stream: widget.iotService.updateApp(url: url),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CustomLoadingAnimation(size: 40));
              }

              final status = snapshot.data!.status;
              final val = snapshot.data!.value ?? "0";

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                    status.name,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$val%",
                    style: GoogleFonts.robotoMono(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _editPhotoUrl() {
    final ctrl = TextEditingController(text: widget.iotService.photoUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          "IMAGE URL",
          style: GoogleFonts.robotoMono(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://...",
            filled: true,
            fillColor: Colors.white10,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              widget.iotService.updateProfilePhoto(ctrl.text.trim());
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text(
              "SAVE",
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (widget.iotService.photoUrl != null &&
        widget.iotService.photoUrl!.startsWith("http")) {
      avatarImage = NetworkImage(widget.iotService.photoUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "PROFILE",
          style: GoogleFonts.robotoMono(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. AVATAR
            GestureDetector(
              onTap: _editPhotoUrl,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.cyanAccent.withValues(alpha: 0.2),
                backgroundImage: avatarImage,
                onBackgroundImageError: avatarImage != null ? (_, _) {} : null,
                child: avatarImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Tap to change photo",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 30),

            // 2. NAME FIELD
            TextField(
              controller: _nameController,
              style: GoogleFonts.robotoMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "DISPLAY NAME",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.badge, color: Colors.cyanAccent),
              ),
            ),
            const SizedBox(height: 20),

            // 3. DATABASE URL FIELD
            TextField(
              controller: _urlController,
              style: GoogleFonts.robotoMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: "FIREBASE DATABASE URL",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "https://...firebaseio.com",
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: const Icon(Icons.link, color: Colors.cyanAccent),
              ),
            ),
            const SizedBox(height: 30),

            // 4. FIRMWARE UPDATE BUTTON (Added back to fix unused_element error)
            ListTile(
              onTap: _runUpdate,
              tileColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(
                Icons.system_update,
                color: Colors.orangeAccent,
              ),
              title: Text(
                "CHECK FIRMWARE UPDATE",
                style: GoogleFonts.robotoMono(color: Colors.white),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ),
            const SizedBox(height: 20),

            // 5. SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _saveSettings,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        "SAVE & CONNECT",
                        style: GoogleFonts.robotoMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text(
                  "LOGOUT",
                  style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
