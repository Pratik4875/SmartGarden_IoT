# Smart Garden IoT 🌿

A complete IoT solution for automated plant watering and monitoring using ESP8266 and Flutter.

## Features
- **Remote Monitoring**: View Soil Moisture, Temperature (optional), and Pump Status in real-time via the App.
- **Smart Control**: Manually toggle the pump or let the automation handle it based on soil moisture levels.
- **History & Analysis**: View historical data graphs and daily insights (Min/Max Moisture).
- **Auto-Lock**: Safety feature to automatically turn off the pump after 15 seconds to prevent overflow.
- **Cooldown**: Prevents rapid toggling of the pump.
- **Scheduler**: Set specific times for watering.

## Getting Started

### Prerequisites
1.  **Hardware**: ESP8266 (NodeMCU or D1 Mini), Soil Moisture Sensor (Analog), Relay Module, Water Pump.
2.  **Software**: Arduino IDE, Flutter SDK.
3.  **Cloud**: Firebase Account (Realtime Database).

---

### Step 1: Firebase Setup
1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Create a new project.
3.  Navigate to **Realtime Database** and create a database (Start in **Test Mode** or configure rules to `true` for read/write for testing).
4.  Copy your **Database URL** (e.g., `https://your-project.firebaseio.com/`).
5.  Go to **Project Settings** -> **Service Accounts** -> **Database Secrets** and copy the **Secret**.

### Step 2: Hardware Setup (ESP8266)
1.  Open `Arduino/src/Main/Main.ino` in Arduino IDE.
2.  Install required libraries: `FirebaseESP8266`, `ArduinoJson`, `NTPClient`.
3.  **Configuration**:
    -   Rename `secrets_template.h` to `secrets.h`.
    -   Fill in your WiFi credentials, Firebase URL, and Secret.
    ```cpp
    #define WIFI_SSID "YourWiFiName"
    #define WIFI_PASSWORD "YourWiFiPass"
    #define DB_URL "https://your-project.firebaseio.com"
    #define DB_SECRET "YourFirebaseSecret"
    ```
4.  Upload the code to your ESP8266.

### Step 3: App Setup (Flutter)
1.  Navigate to the `app` directory.
2.  Run `flutter pub get` to install dependencies.
3.  **Connect**:
    -   Open the App.
    -   Enter your **Firebase Database URL** when prompted (or in Settings).
    -   The app will automatically connect to your garden!

---

## Directory Structure
-   `Arduino/`: Code for the ESP8266 microcontroller.
-   `app/`: Flutter mobile application source code.
-   `docs/`: Documentation and screenshots.

## Photos
*(This is where you can upload photos of your setup)*
<!-- Add your photos in the docs/photos folder and link them here -->
<!-- ![My Setup](docs/photos/setup.jpg) -->

## License
MIT