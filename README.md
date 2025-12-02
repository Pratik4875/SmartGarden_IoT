🌱 EcoSync IoT

Smart Automation for a Greener Home. 🌿

EcoSync transforms your garden into a secure, data-driven IoT ecosystem. It combines a solar-powered ESP8266 controller with a professional Flutter app to provide real-time telemetry, precision watering schedules, and historical analytics—all secured by enterprise-grade authentication.

📱 App Interface

Secure Login Hub

Real-Time Dashboard

Analytics & History

<img src="docs/login.png" width="250" alt="Login Screen">

<img src="docs/dashboard.png" width="250" alt="Dashboard">

<img src="docs/history.png" width="250" alt="History Graphs">

Connect securely to your personal IoT Hub.

Control pump, set schedules, and view sensors.

Visualize temp/moisture trends over 24h.

🚀 Key Features

🔒 Enterprise Security

Hub Connection: No hardcoded secrets. Users connect via a secure Login Screen.

Anonymous Auth: Silent, encrypted handshake ensures only your app talks to the database.

Database Secrets: Firmware uses privileged Admin tokens to bypass locked rules safely.

⏱️ Precision Automation

Daily Scheduler: Set specific start times and exact durations (e.g., "Water for 15 seconds at 9:00 AM").

Unified Logic: Intelligent firmware resolves conflicts between Manual overrides and Scheduled tasks.

Safety Cutoff: Hard-coded dynamic limit prevents flooding even if WiFi fails.

📊 Data Intelligence

History Logger: ESP8266 snapshots sensor data every 60 minutes.

Interactive Graphs: View Soil Moisture and Temperature trends to optimize plant health.

🔄 DevOps & Quality

Auto-Update: The app intelligently checks GitHub Releases and installs new versions (v1.4+) automatically.

Power Optimization: WIFI_NONE_SLEEP mode ensures compatibility with power banks by preventing auto-shutdown.

🏗 Architecture

The system operates on a Dual-Power Architecture (Solar + Lithium Buffer) and uses a robust REST API protocol.

Uplink (Telemetry): Pushes DHT11 and Soil data every 10 seconds.

Downlink (Control): Polls command queue every 200ms for instant reaction.

Loglink (History): Pushes snapshot to /history every 1 hour.

🔌 Hardware Stack

MCU: ESP8266 (NodeMCU/Wemos D1 Mini)

Sensors: DHT11 (Temp/Hum), Capacitive Soil Moisture v1.2

Actuators: 5V Relay (Active Low / Open-Drain)

Power: 45x80mm Solar Panel → TP4056 → Li-Ion → 5V Boost

🛠️ Installation Guide

1. Firmware (ESP8266)

Clone this repo.

Navigate to Arduino/src/.

Rename secrets_template.h to secrets.h.

Add your WiFi creds and Database Secret (from Firebase Console).

Flash via USB (recommended for security updates) or OTA.

2. Mobile App (Flutter)

Navigate to app/.

Run flutter pub get.

Run flutter build apk --release or install via Releases.

📄 License

Distributed under the MIT License. See LICENSE for more information.

Built with 💚 by Pratik4875