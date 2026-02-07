# 🌿 Setting Up a New Smart Garden System

This guide explains how to set up a completely fresh system (New ESP8266 + New Firebase Database) while using the existing App.

## 1. Create a New Firebase Project
Since you want a "new system", you need a new database so the data doesn't mix with your old one.

1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add Project** -> Name it (e.g., "SmartGarden-Student1").
3.  **Disable Google Analytics** (keeps it simple) -> Create Project.
4.  Go to **Build** -> **Realtime Database** -> **Create Database**.
    *   Select a location (e.g., Singapore/US).
    *   **Start in Test Mode** (easiest for setup).
5.  **Get Credentials**:
    *   **Database URL**: Copy the URL at the top of the Data tab (e.g., `https://smartgarden-student1-default-rtdb.asia-southeast1.firebasedatabase.app/`).
    *   **Database Secret**: Go to **Project Settings** (Gear icon) -> **Service Accounts** -> **Database Secrets**.
        *   Hover over the secret and click **Show**. Copy it.

## 2. Flash the New ESP8266
Now we need to tell the new hardware to talk to *this* new database.

1.  Open the `SmartGarden_IoT` project in **Arduino IDE**.
2.  Open `Arduino/src/Main/secrets.h`.
3.  **Update the Credentials**:
    *   `WIFI_SSID` & `WIFI_PASSWORD`: Your local WiFi details where the device will live.
    *   `DB_URL`: Paste the **NEW** Firebase URL you copied above.
    *   `DB_SECRET`: Paste the **NEW** Secret you copied above.
4.  **Upload Code**:
    *   Connect your new ESP8266 via USB.
    *   Select the correct Board (NodeMCU 1.0) and Port.
    *   Click **Upload** (Right Arrow).

## 3. Connect the App
You don't need a "new app". The existing EcoSync app supports multiple systems!

1.  Open the **EcoSync App** on your phone.
2.  If you are logged in, go to **Profile** -> **Logout** (or just clear app data).
3.  On the Login Screen, you will see a **Firebase URL** field.
4.  **Paste the NEW Database URL** here.
    *   *Tip: You can email/WhatsApp this URL to the student so they can just paste it.*
5.  Click **Connect / Login**.

🎉 **Done!** The app is now talking to the *new* database, which talks to the *new* ESP8266. The old system is untouched.
