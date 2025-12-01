SmartGarden IoT 🌿

A professional, solar-powered IoT irrigation system. This project integrates an ESP8266 microcontroller with Firebase Realtime Database and a Flutter App to provide global access to pump controls and sensor telemetry.

📱 App Interface

Dashboard

Real-Time Control

Add screenshots here

Add screenshots here

🔒 Security Setup (Important)

This repository follows strict security practices. Private credentials are not included.

To Run the Firmware:

Navigate to Arduino/src/.

Rename secrets_template.h to secrets.h.

Fill in your credentials:

#define WIFI_SSID "your_wifi"
#define WIFI_PASSWORD "your_password"
#define API_KEY "your_firebase_api_key"
#define DB_URL "your_db_url"


To Run the App:

You must generate your own firebase_options.dart using flutterfire configure.

🏗 Architecture

The system operates on a dual-power architecture (Solar + Lithium Battery) and uses a bi-directional data stream:

Uplink (Telemetry): ESP8266 pushes DHT11 (Temp/Hum) and Capacitive Soil data to Firebase every 10 seconds.

Downlink (Control): ESP8266 polls Firebase (500ms interval) for pump_switch status.

🔌 Hardware Stack

MCU: ESP8266 (NodeMCU/Wemos D1 Mini)

Sensors: * DHT11 (Temperature & Humidity)

Capacitive Soil Moisture Sensor v1.2

Actuators: 5V Relay (Open-Drain Configuration)

Power System:

45x80mm Solar Panel (4.45V) -> TP4056 -> Li-Ion Battery (Pump)

5000mAh Power Bank (MCU)

🚀 Key Features

Global Remote Control: Toggle water pump from anywhere via Flutter App.

Power Bank Keep-Alive: Firmware v1.5 uses WIFI_NONE_SLEEP to prevent power banks from auto-shutting down due to low current draw.

Safety Cutoff: Hard-coded 2000s limit prevents flooding if connectivity is lost.

Integer Overflow Protection: Custom timer logic prevents "time travel" bugs during long uptime.

🛠️ Installation

Firmware (ESP8266)

Clone the repo.

Open Arduino/ in VS Code (PlatformIO) or Arduino IDE.

Setup secrets.h.

Flash to device.

Mobile App (Flutter)

Navigate to app/.

Run flutter pub get.

Run flutter run.

📄 License

Distributed under the MIT License. See LICENSE for more information.