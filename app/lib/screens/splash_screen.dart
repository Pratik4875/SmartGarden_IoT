import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_loading_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start a 3-second timer, then navigate to Auth Check
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Use replacement so user can't go back to Splash
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027), // Deep dark background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Animation (Zoom In effect could be added here later)
            SizedBox(
              width: 150,
              height: 150,
              child: SvgPicture.asset('assets/logo.svg'),
            ),
            const SizedBox(height: 30),

            // App Name
            Text(
              "ECOSYNC",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
              ),
            ),

            // Slogan
            Text(
              "Smart Garden Automation",
              style: GoogleFonts.poppins(
                color: Colors.cyanAccent,
                fontSize: 14,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Indicator
            const CustomLoadingAnimation(size: 50),
          ],
        ),
      ),
    );
  }
}
