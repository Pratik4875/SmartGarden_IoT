import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../widgets/custom_loading_animation.dart'; // Import new loader

class SplashScreen extends StatefulWidget {
  final Duration splashDuration;
  final WidgetBuilder nextScreenBuilder;

  const SplashScreen({
    super.key,
    required this.nextScreenBuilder,
    this.splashDuration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.splashDuration, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: widget.nextScreenBuilder));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 1. LOGO
              SizedBox(
                width: 150,
                height: 150,
                child: SvgPicture.asset('assets/logo.svg'),
              ),

              const SizedBox(height: 40),

              // 2. BRANDING TEXT
              Text(
                'ECOSYNC',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              Text(
                'Smart Automation Hub',
                style: GoogleFonts.poppins(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),

              const Spacer(flex: 1),

              // 3. NEW WAVE ANIMATION
              const CustomLoadingAnimation(
                size: 50,
              ), // 50 looks cleaner than 200 for a footer

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
