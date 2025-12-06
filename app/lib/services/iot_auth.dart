import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

abstract class AuthClient {
  DatabaseReference? get db;
  FirebaseAuth get firebaseAuth;
  bool get isConnected;

  void updateUserName(String name);
  String get userName;
}

class IoTAuth {
  final AuthClient _client;

  // GoogleSignIn instance (v7.x no longer supports unnamed constructors)
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  IoTAuth(this._client);

  /// Ensure GoogleSignIn is initialized with serverClientId
  static Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            "155609412514-12n7pftdifd5699mbsetegu1kclj91i0.apps.googleusercontent.com",
      );
    } catch (e) {
      // ignore if already initialized
      debugPrint("GoogleSignIn init warning: $e");
    }
  }

  /// GOOGLE SIGN-IN (v7.x)
  static Future<UserCredential?> signInWithGoogle() async {
    await _initGoogleSignIn();

    try {
      // v7.x: authenticate() replaces signIn()
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser == null) return null;

      // v7.x: authentication is synchronous
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("❌ Google Sign-In Error: $e");
      return null;
    }
  }

  /// EMAIL REGISTER
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _client.firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(name);
      _client.updateUserName(name);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      if (_client.isConnected && _client.db != null) {
        await _client.db!.child('users/${userCredential.user!.uid}').set({
          'name': name,
          'email': email,
          'joined': ServerValue.timestamp,
        });
      }

      return userCredential;
    } catch (e) {
      debugPrint("❌ Registration Error: $e");
      rethrow;
    }
  }

  /// EMAIL LOGIN
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _client.firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      _client.updateUserName(userCredential.user?.displayName ?? "User");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _client.userName);

      return userCredential;
    } catch (e) {
      debugPrint("❌ Login Error: $e");
      rethrow;
    }
  }

  /// SIGN OUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google sign-out error: $e");
    }

    await _client.firebaseAuth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
