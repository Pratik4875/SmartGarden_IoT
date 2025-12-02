import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  // NEW: Optional callback for testing
  final Function(String url)? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _wifiSsidController = TextEditingController();
  final _wifiPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('firebase_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _urlController.text = savedUrl;
      _wifiSsidController.text = prefs.getString('wifi_ssid') ?? "";
      _wifiPassController.text = prefs.getString('wifi_pass') ?? "";
    }
  }

  Future<void> _saveAndConnect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    String url = _urlController.text.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    await prefs.setString('firebase_url', url);
    await prefs.setString('wifi_ssid', _wifiSsidController.text.trim());
    await prefs.setString('wifi_pass', _wifiPassController.text.trim());

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // TEST HOOK: If a test provided a callback, run it and STOP.
      // This prevents the app from trying to load Dashboard/Firebase during tests.
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(url);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(databaseUrl: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.hub, size: 80, color: Colors.greenAccent),
                const SizedBox(height: 20),
                Text(
                  'ECOSYNC',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Connect to your IoT Hub',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                _buildTextField(
                  controller: _urlController,
                  label: "Firebase Database URL",
                  icon: Icons.cloud,
                  hint: "https://your-project...firebasedatabase.app",
                  validator: (val) {
                    if (val == null || val.isEmpty) return "URL is required";
                    if (!val.startsWith("http"))
                      return "Must start with http/https";
                    if (val.contains("console.firebase.google.com"))
                      return "Don't use the Console Link! Use the Database Link.";
                    if (!val.contains("firebaseio.com") &&
                        !val.contains("firebasedatabase.app"))
                      return "Invalid Firebase Database URL";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "WiFi Provisioning (Optional)",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _wifiSsidController,
                  label: "WiFi Name (SSID)",
                  icon: Icons.wifi,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _wifiPassController,
                  label: "WiFi Password",
                  icon: Icons.lock,
                  isObscure: true,
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : Text(
                          "CONNECT HUB",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[800]),
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
        errorMaxLines: 3,
      ),
    );
  }
}
