# release_guide.md

## 🚀 How to Publish a Release on GitHub

This guide helps you upload your new App (`.apk`), ESP Firmware (`.bin`), and screenshots.

### 1. Build & Collect Files
You need these files:
1.  **Android App**:
    -   Located at: `app/build/app/outputs/flutter-apk/app-release.apk`
    -   👉 **Recommend**: Rename this file to `EcoSync.apk` (to match your previous versions).
    -   *Note: This file contains the update logic!*
2.  **ESP Firmware** (Optional):
    -   Open Arduino IDE -> `Main.ino`.
    -   Go to **Sketch** -> **Export Compiled Binary**.
    -   Find the `.bin` in the sketch folder.

### 2. Create GitHub Release
1.  Go to your repo: [https://github.com/Pratik4875/SmartGarden_IoT](https://github.com/Pratik4875/SmartGarden_IoT)
2.  Click **Releases** (sidebar) -> **Draft a new release**.
3.  **Target**: Select `feature/hybrid-ui` (since we pushed code there) or `main` (if you merged).
4.  **Choose a tag**: Create a NEW tag (e.g., `v2.0`).
    -   *Crucial*: The app checks for a tag higher than the current version!
5.  **Release Title**: "Smart Garden v2.0".
6.  **Description**:
    -   **🖼️ Uploading Images**: You can drag & drop your screenshots directly into this description box! They will appear as a gallery.
    -   *Tip: This is the best place for images.*
7.  **Attach Binaries**:
    -   Drag and drop `EcoSync.apk` here.
    -   (Optional) Drag and drop firmware `.bin`.
8.  Click **Publish release**.

### 3. Verify Update
1.  Open the app -> Profile -> **CHECK FIRMWARE UPDATE**.
2.  It should detect `v2.0` and ask to update!

### 📂 Repository Photos (Optional)
If you want to store images in the code:
1.  Put them in `docs/photos/`.
2.  Commit and Push.
3.  Link them in `README.md`.
