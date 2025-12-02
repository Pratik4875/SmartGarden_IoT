/*
  RENAME THIS FILE TO "secrets.h" AND FILL IN YOUR CREDENTIALS
*/

#ifndef SECRETS_H
#define SECRETS_H

#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// 1. Web API Key (From Firebase Project Settings -> General)
#define API_KEY "YOUR_FIREBASE_WEB_API_KEY"

// 2. Database URL (From Realtime Database -> Data)
#define DB_URL "https://your-project-id.firebasedatabase.app"

// 3. Database Secret (From Project Settings -> Service Accounts -> Database Secrets)
// This grants Admin access to the ESP8266
#define DB_SECRET "YOUR_LONG_DATABASE_SECRET_HERE"

#define DEVICE_ID "esp8266_01"

#endif