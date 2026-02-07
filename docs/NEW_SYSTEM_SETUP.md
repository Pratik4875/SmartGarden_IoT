# 🌿 Setting Up a New Smart Garden System

This guide explains how to set up a completely fresh system (New ESP8266 + New Firebase Database) while using the existing App.

## 0. Prerequisites (Install Libraries)
Before you start, you must install the required libraries in Arduino IDE.
**Sketch** -> **Include Library** -> **Manage Libraries...**
Search for and install:
1.  **ArduinoJson** (by Benoit Blanchon) - *Select Version 6.x.x*
2.  **NTPClient** (by Fabrice Weinberg)

## 1. Create a New Firebase Project
Since you want a "new system", you need a new database so the data doesn't mix with your old one.

1.  Go to [Firebase Console](https://console.firebase.google.com/).
2.  Click **Add Project** -> Name it (e.g., "SmartGarden-Student1").
3.  **Disable Google Analytics** (keeps it simple) -> Create Project.
4.  Go to **Build** -> **Realtime Database** -> **Create Database**.
    *   Select a location (e.g., Singapore/US).
    *   **Start in Test Mode** (easiest for setup).
    *   *Note: "Test Mode" means you don't need complex rules. Students won't face permission errors.*
5.  **Get Credentials**:
    *   **Database URL**: Copy the URL at the top of the Data tab (e.g., `https://smartgarden-student1-default-rtdb.asia-southeast1.firebasedatabase.app/`).
    *   **Database Secret**: Go to **Project Settings** (Gear icon) -> **Service Accounts** -> **Database Secrets**.
        *   Hover over the secret and click **Show**. Copy it.

### ⚠️ IMPORTANT: Configure Database Rules
If the app is not reacting (can't turn on pump), the database might be "Locked".
1.  Go to **Realtime Database** -> **Rules**.
2.  Change them to this (Test Mode = Public):
    ```json
    {
      "rules": {
        ".read": true,
        ".write": true
      }
    }
    ```
3.  Click **Publish**. Now the App can write to the database!

### ❓ Common Questions
*   **Do I need to create tables/fields?**
    *   **NO!** You just create the empty database. The ESP8266 code will automatically create all the necessary fields (`status`, `sensors`, `control`) the moment it turns on. No manual work needed!
*   **Do I need SHA-1 Keys or Google Login setup?**
    *   **NO!** Since you are using the pre-built `EcoSync.apk`, you skip all that. The app uses a special "Universal Connection" mode. You just paste the URL, and it works. No certificates required!

## 2. Flash the New ESP8266
You will use the **Standard / Normal Code** (`Main.ino`) for the students. This assumes a standard relay or MOSFET setup.

1.  Open the `SmartGarden_IoT` project in **Arduino IDE**.
2.  **Select the File**: Verify you are editing `Arduino/src/Main/Main.ino`.
    *   *Do NOT use `Main_Buck.ino` unless you are specifically using a Buck Converter setup.*
3.  **Configure Secrets**:
    *   Copy `Arduino/src/Main/secrets_template.h` to `Arduino/src/Main/secrets.h`.
    *   Open `secrets.h`.
    *   Update `WIFI_SSID`, `WIFI_PASSWORD`, `DB_URL`, and `DB_SECRET` with the new values.
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
