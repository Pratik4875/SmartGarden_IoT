import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'home_screen.dart';
import '../services/iot_service.dart';
import '../widgets/custom_loading_animation.dart';
import '../widgets/google_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegistering = false;
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final GlobalKey<SlideActionState> _slideKey = GlobalKey();
  bool _isLoading = false;
  final IoTService _iotService = IoTService();

  Future<void> _handleEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isRegistering) {
        if (_nameController.text.isEmpty) throw "Name is required";
        await _iotService.registerWithEmail(
          _emailController.text.trim(),
          _passController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        await _iotService.loginWithEmail(
          _emailController.text.trim(),
          _passController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _slideKey.currentState?.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${e.toString().replaceAll("Exception:", "")}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final credential = await IoTService.signInWithGoogle();

    if (credential != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                _isRegistering ? "Create Account" : "Welcome Back",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),
              if (_isRegistering) ...[
                _buildTextField(_nameController, "Full Name", Icons.person),
                const SizedBox(height: 15),
              ],
              _buildTextField(_emailController, "Email Address", Icons.email),
              const SizedBox(height: 15),
              _buildTextField(
                _passController,
                "Password",
                Icons.lock,
                isObscure: true,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CustomLoadingAnimation(size: 50)
              else
                SlideAction(
                  key: _slideKey,
                  borderRadius: 16,
                  elevation: 0,
                  height: 60,
                  innerColor: const Color(0xFF0F2027),
                  outerColor: Colors.cyanAccent,
                  text: _isRegistering ? "SLIDE TO REGISTER" : "SLIDE TO LOGIN",
                  textStyle: GoogleFonts.poppins(
                    color: const Color(0xFF0F2027),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  sliderButtonIcon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.cyanAccent,
                  ),
                  submittedIcon: const Icon(
                    Icons.check_rounded,
                    color: Colors.cyanAccent,
                    size: 30,
                  ),
                  onSubmit: _handleEmailAuth,
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() {
                  _isRegistering = !_isRegistering;
                  _slideKey.currentState?.reset();
                }),
                child: Text(
                  _isRegistering
                      ? "Already have an account? Log In"
                      : "New User? Create Account",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              const Divider(color: Colors.white10, height: 40),

              // NEW ANIMATED BUTTON INTEGRATION
              GoogleButton(
                isLoading: _isLoading,
                onPressed: _handleGoogleLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
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
      ),
    );
  }
}
