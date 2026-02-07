#ifndef SECRETS_H
#define SECRETS_H

// ==========================================
// 🌿 SMART GARDEN CONFIGURATION 🌿
// ==========================================
// INSTRUCTIONS:
// 1. Enter your WiFi and Firebase details below inside the quotes "".
// 2. Save this file.
// 3. Rename this file from "secrets_template.h" to "secrets.h" before uploading!
// ==========================================

// --- 1. WiFi Settings ---
#define WIFI_SSID     "YOUR_WIFI_NAME_HERE"      // Example: "MyHomeWiFi"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD_HERE"  // Example: "password123"

// --- 2. Firebase Database Settings ---
// Get these from your Firebase Console -> Project Settings -> Service Accounts -> Database Secrets

// The URL of your Realtime Database (ends with .firebasedatabase.app or .firebaseio.com)
#define DB_URL        "https://YOUR-PROJECT-ID-default-rtdb.asia-southeast1.firebasedatabase.app/" 

// The Secret Key for your Database
#define DB_SECRET     "YOUR_FIREBASE_DATABASE_SECRET_HERE"

#endif