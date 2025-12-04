import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
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

  final GlobalKey<SlideActionState> _slideKey = GlobalKey();

  // Used to lock the TEXT FIELDS while connecting, but not hide the slider
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

  Future<void> _handleConnect() async {
    // 1. Validate Inputs
    if (!_formKey.currentState!.validate()) {
      // If invalid, immediately reset slider so user can try again
      _slideKey.currentState?.reset();
      return;
    }

    // 2. Lock Inputs (Optional)
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String url = _urlController.text.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      await prefs.setString('firebase_url', url);
      await prefs.setString('wifi_ssid', _wifiSsidController.text.trim());
      await prefs.setString('wifi_pass', _wifiPassController.text.trim());

      // Simulate network delay (Slider shows loading spinner during this)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!(url);
          return;
        }

        // Navigate to Dashboard (Slider shows Tick during transition)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(databaseUrl: url),
          ),
        );
      }
    } catch (e) {
      // On error, reset UI so they can try again
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _slideKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _wifiSsidController.dispose();
    _wifiPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          // Disable text editing while connecting
          child: IgnorePointer(
            ignoring: _isLoading,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BRANDING
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: SvgPicture.asset('assets/logo.svg'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ECOSYNC',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // INPUT CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FIREBASE CONNECTION",
                          style: GoogleFonts.poppins(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _urlController,
                          label: "Database URL",
                          icon: Icons.cloud_queue,
                          hint: "https://project-id...firebasedatabase.app",
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Required";
                            }
                            if (!val.startsWith("http")) {
                              return "Invalid URL";
                            }
                            if (val.contains("console.firebase")) {
                              return "Don't use Console URL!";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        Text(
                          "WIFI SETUP (OPTIONAL)",
                          style: GoogleFonts.poppins(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          controller: _wifiSsidController,
                          label: "SSID",
                          icon: Icons.wifi,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _wifiPassController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          isObscure: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // SLIDE TO CONNECT (With Tick Animation)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      key: const Key('loginSliderArea'), // stable test key
                      child: SlideAction(
                        key: _slideKey, // keep the GlobalKey for reset() usage
                        borderRadius: 16,
                        elevation: 0,
                        height: 60,
                        outerColor: Colors.cyanAccent.withValues(alpha: 0.9),
                        innerColor: const Color(0xFF0F2027),

                        // Text
                        text: "SLIDE TO CONNECT",
                        textStyle: GoogleFonts.poppins(
                          color: const Color(0xFF0F2027),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),

                        // Icons
                        sliderButtonIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.cyanAccent,
                        ),
                        submittedIcon: const Icon(
                          Icons.check_rounded, // The TICK you wanted!
                          color: Colors.cyanAccent,
                          size: 30,
                        ),

                        // Action
                        onSubmit: _handleConnect,
                      ),
                    ),
                  ),
                ],
              ),
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
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }
}
