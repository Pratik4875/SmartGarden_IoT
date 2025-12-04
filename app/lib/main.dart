import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
// Ensure this path is correct and the file contains class 'SplashScreen'
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // Print a useful message for tests/CI; don't rethrow so tests can handle startup gracefully.
    // Remove or change this in production if you want to fail fast.
    debugPrint('Firebase initialization error: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<String?> _savedUrlFuture;

  @override
  void initState() {
    super.initState();
    _savedUrlFuture = _getSavedUrl();
  }

  Future<String?> _getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_url');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: _savedUrlFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F0F10),
              body: Center(
                child: CircularProgressIndicator(color: Colors.cyan),
              ),
            );
          }

          final savedUrl = snapshot.data;

          // Calling the SplashScreen constructor we fixed previously
          return SplashScreen(
            splashDuration: const Duration(seconds: 4),
            nextScreenBuilder: (context) {
              if (savedUrl != null && savedUrl.isNotEmpty) {
                return DashboardScreen(databaseUrl: savedUrl);
              } else {
                return const LoginScreen();
              }
            },
          );
        },
      ),
    );
  }
}
