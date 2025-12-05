import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ota_update/ota_update.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.iotService.userName;
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _urlController.text = prefs.getString('firebase_url') ?? "";
      });
    }
  }

  // --- UPDATE LOGIC ---
  void _runUpdate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "System Update",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          height: 120,
          child: StreamBuilder<OtaEvent>(
            stream: widget.iotService.updateApp(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomLoadingAnimation(size: 40),
                      SizedBox(height: 15),
                      Text(
                        "Connecting...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }

              final status = snapshot.data!.status;
              String val = snapshot.data!.value ?? "0";

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status == OtaStatus.DOWNLOADING)
                    LinearProgressIndicator(
                      value: (double.tryParse(val) ?? 0) / 100,
                      color: Colors.cyanAccent,
                      backgroundColor: Colors.white10,
                    )
                  else
                    const CustomLoadingAnimation(size: 40),

                  const SizedBox(height: 15),
                  Text(
                    "${status.name} $val%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPhotoDialog() {
    final TextEditingController photoCtrl = TextEditingController(
      text: widget.iotService.photoUrl,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          "Change Profile Picture",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter Image URL:",
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: photoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "https://...",
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (photoCtrl.text.isNotEmpty) {
                await widget.iotService.updateProfilePhoto(
                  photoCtrl.text.trim(),
                );
                if (mounted) setState(() {});
              }

              // FIX — DO NOT create ctx, use dialogCtx directly
              Navigator.pop(dialogCtx);
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

  Future<void> _saveDatabaseUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || !url.startsWith("http")) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid URL")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_url', url);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Garden Linked! Restarting...")),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Profile", style: GoogleFonts.poppins(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.iotService.photoUrl != null
                        ? Image.network(
                            widget.iotService.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showPhotoDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Name Field
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Display Name",
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.cyanAccent),
                  onPressed: () async {
                    final ctx = context; // FIX — must come before await

                    await widget.iotService.updateProfileName(
                      _nameController.text,
                    );

                    if (!mounted) return;

                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(const SnackBar(content: Text("Name Saved")));

                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // DB Link
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.link, color: Colors.orangeAccent),
                      const SizedBox(width: 10),
                      Text(
                        "Link Garden Database",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "https://...",
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                      ),
                      onPressed: _saveDatabaseUrl,
                      child: const Text(
                        "SAVE & CONNECT",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ListTile(
              onTap: _runUpdate,
              tileColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.system_update,
                color: Colors.cyanAccent,
              ),
              title: Text(
                "Check for Updates",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ),

            const SizedBox(height: 20),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: Text(
                  "Sign Out",
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  final ctx = context; // FIX — must come before await

                  await widget.iotService.signOut();

                  if (!mounted) return;

                  Navigator.of(ctx).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
