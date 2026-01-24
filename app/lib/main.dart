import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart'; // Import Splash
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/custom_loading_animation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Lock Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EcoSyncApp());
}

class EcoSyncApp extends StatelessWidget {
  const EcoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSync IoT',
      debugShowCheckedModeBanner: false,

      // Global Dark Theme
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        primaryColor: Colors.cyanAccent,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
        ),
      ),

      // FIX: Start with Splash Screen
      home: const SplashScreen(),

      // Define a route for the Auth Wrapper
      routes: {'/auth': (context) => const AuthWrapper()},
    );
  }
}

// --- AUTH WRAPPER ---
// Handles the Login vs Home logic
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: CustomLoadingAnimation(size: 60));
        }

        if (snapshot.hasData) {
          return const HomeScreen(); // User is logged in
        }

        return const LoginScreen(); // User needs to login
      },
    );
  }
}
