# release_guide.md

## 🚀 How to Publish a Release on GitHub

This guide helps you upload your new App (`.apk`) and ESP Firmware (`.bin`) so users (and the app itself!) can download updates.

### 1. Build & Collect Files
You should have the following files ready:
1.  **Android App**: `app/build/app/outputs/flutter-apk/app-release.apk`
2.  **ESP Firmware**: 
    -   Open Arduino IDE -> `Main.ino`.
    -   Go to **Sketch** -> **Export Compiled Binary**.
    -   Find the `.bin` file in the sketch folder (e.g., `Main.ino.generic.bin`).

### 2. Create GitHub Release
1.  Go to your repository: [https://github.com/Pratik4875/SmartGarden_IoT](https://github.com/Pratik4875/SmartGarden_IoT)
2.  Click **Releases** (on the right sidebar) -> **Draft a new release**.
3.  **Choose a tag**: Create a new version tag (e.g., `v2.0`). This is CRITICAL for the app to detect an update.
    -   *If your app detects `v1.5` and the tag is `v2.0` -> Update Found!*
4.  **Release Title**: "Smart Garden v2.0 - Auto-Lock & History Upgrade".
5.  **Description**:
    ```markdown
    ## New Features 🌿
    - **App Update**: The app now auto-updates!
    - **Pump Safety**: Auto-lock after 15s to prevent overflow.
    - **History**: View soil moisture history for the last 12 hours.
    - **UI**: Improved "Last Run" times and moisture insights.
    ```
6.  **Attach Binaries**:
    -   Drag and drop `app-release.apk` here.
    -   (Optional) Drag and drop your ESP `.bin` file here.
7.  Click **Publish release**.

### 3. Verify Update
1.  Open your current installed app.
2.  Go to **Profile**.
3.  Tap **CHECK FIRMWARE UPDATE**.
4.  It should say "Update Available (v2.0)" and offer to download.

---
**Note**: The app downloads the file named `EcoSync_<timestamp>.apk` to avoid conflicts. It requires "Install Unknown Apps" permission on Android.
