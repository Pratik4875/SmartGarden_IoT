# 🌱 Smart Garden IoT

**"The Intelligent Upgrade"**

A complete IoT solution for automated plant watering and monitoring using ESP8266 and Flutter.
This project integrates real-time soil moisture tracking, smart pump control, and historical analytics into a beautiful, cross-platform mobile app.

---

## 📸 Visual Tour
*Experience the fresh look of EcoSync v2.0:*

| Dashboard & Controls | Settings & Profile |
|:---:|:---:|
| ![Dashboard](https://github.com/user-attachments/assets/4cd5c94e-be17-4e36-bbea-bb209bb83271) | ![Profile](https://github.com/user-attachments/assets/e4544493-d7b2-4942-afae-7f00af1567a1) |
| ![Control](https://github.com/user-attachments/assets/bf2ef2a3-1786-4ede-929a-382f52f5c8f5) | ![Settings](https://github.com/user-attachments/assets/906d000d-d277-46bd-97f6-aa55758e7f48) |

### 📊 History & Analytics
![Analytics](https://github.com/user-attachments/assets/54ac5eda-487f-4744-a632-7c454f2f2d55)
![Graphs](https://github.com/user-attachments/assets/0ad1d3a5-4da6-451c-ba3b-dc87c7875f10)

### 🌿 Smart Setup & Login
| | |
|:---:|:---:|
| ![Login](https://github.com/user-attachments/assets/e1d142dd-8b86-4466-b930-c90366545e9f) | ![Setup](https://github.com/user-attachments/assets/06c07c66-a918-4bf3-b55c-5858a5d782d7) |
| ![Welcome](https://github.com/user-attachments/assets/19756746-a66b-4124-bf31-fc354681847e) | ![Connect](https://github.com/user-attachments/assets/a8db412a-1aaf-4933-8b7f-7ddf9704f11c) |

### 🎨 Themes & Design Details
![Design 1](https://github.com/user-attachments/assets/5aafc27a-fa51-4443-8334-bbd69b04f3c4)
![Design 3](https://github.com/user-attachments/assets/499714d6-50df-4210-bfe6-88a3ed44885c)

---

## 🚀 Key Features

### 📱 Mobile App (EcoSync)
- **Hybrid UI**: A stunning new interface with glassmorphism, animated status indicators, and responsive design.
- **Real-Time Monitoring**: Live updates for Soil Moisture and Pump Status (every 5 seconds).
- **History & Insights**: Detailed graphs and daily min/max moisture analysis.
- **Smart Updates**: In-app OTA updates directly from GitHub Releases.
- **Multi-System Support**: Easily switch between different gardens by changing the Database URL.

### 🧠 Firmware (ESP8266)
- **Buck Converter Ready**: Native support for Buck Converter setups (High Trigger = ON).
- **Intelligent Logging**: Live status updates constantly, but history is logged only once per hour to save database space.
- **Auto-Lock Safety**: Automatically turns off the pump after **15 seconds** to prevent flooding.
- **Cool-down Protection**: Prevents the pump from being toggled too frequently (5-second safety delay).
- **OTA Capability**: Update firmware over-the-air without plugging in USB.

---

## 🛠️ Getting Started

### Prerequisites
1.  **Hardware**: ESP8266 (NodeMCU/D1 Mini), Soil Moisture Sensor, Relay Module, Water Pump.
2.  **Software**: Arduino IDE, Flutter SDK (optional, only if building app).
3.  **Cloud**: Firebase Realtime Database (Free Tier).

### Step 1: Firebase Setup
1.  Create a **Firebase Project** and add a **Realtime Database**.
2.  Set Rules to **Test Mode** (`read: true, write: true`).
3.  Copy your **Database URL** and **Database Secret**.

### Step 2: Flash Firmware
1.  Open `Arduino/src/Main/Main.ino`.
2.  Install libraries: `ArduinoJson` (v6), `NTPClient`.
3.  Rename `secrets_template.h` to `secrets.h` and enter your WiFi/Firebase details.
4.  Upload to ESP8266.

### Step 3: Install App
1.  Download the latest `EcoSync.apk` from [Releases](/releases).
2.  Open the app and paste your **Firebase Database URL**.
3.  Connected! 🌿

---

## 📂 Directory Structure
-   `Arduino/`: ESP8266 Firmware (Main.ino supports Buck Converter logic).
-   `app/`: complete Flutter source code.
-   `docs/`: Guides for setup, releasing, and screenshots.

## 📄 License
MIT License