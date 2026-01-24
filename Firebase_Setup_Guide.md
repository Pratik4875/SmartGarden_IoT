# How to Set Up Firebase for Your Smart Garden

Follow these steps to create a new database and get the credentials needed for your `secrets.h` file.

## Step 1: Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **"Add project"** or **"Create a project"**.
3. Enter a name (e.g., `SmartGarden`).
4. You can disable Google Analytics for this project (it's not needed for this simple task) and click **"Create project"**.
5. Wait for it to finish and click **"Continue"**.

## Step 2: Create the Realtime Database
1. In the left sidebar menu, look for **"Build"** and click on **"Realtime Database"**. (Note: Do *NOT* choose Cloud Firestore).
2. Click the **"Create Database"** button.
3. Choose a location (e.g., United States) and click **"Next"**.
4. **Important**: Select **"Start in Test Mode"**.
   - This allows read/write access without complex rules setup for now.
   - *Warning: Anyone with your URL can read your data, but for a personal hobby project, this is the easiest way to start.*
5. Click **"Enable"**.

## Step 3: Get the Database URL
1. Once the database is created, look at the top of the "Data" tab.
2. You will see a URL that starts with `https://` and ends with `.firebasedatabase.app`.
   - Example: `https://smartgarden-12345-default-rtdb.firebaseio.com/`
3. **Copy this URL**.
4. Paste it into your `secrets.h` file effectively replacing `"https://your-project-id.firebasedatabase.app"`.

## Step 4: Get the Database Secret
1. Click the **Gear Icon** (Project Settings) next to "Project Overview" in the top left sidebar.
2. Select **"Project settings"**.
3. Go to the **"Service accounts"** tab.
4. Click on **"Database secrets"**.
   - *Note: You might need to scroll down or look carefully for this sub-tab.*
5. You will see a "Secrets" section. Click **"Show"** to reveal the secret key.
6. **Copy this long string of characters**.
7. Paste it into your `secrets.h` file replacing `"YOUR_DATABASE_SECRET"`.

## Step 5: Verify
Your `secrets.h` should look something like this now:

```cpp
#define WIFI_SSID "TP-Link_Guest_466B"
#define WIFI_PASSWORD "Pnt@107#"

// Paste the URL you copied in Step 3
#define DB_URL "https://smartgarden-12345-default-rtdb.firebaseio.com/"

// Paste the Secret you copied in Step 4
#define DB_SECRET "IsoPL......(really long string)......"
```

## Step 6: Upload Code
1. Connect your ESP8266 to your computer.
2. Select the correct Port in Arduino IDE.
3. Click **Upload**.
4. Open the **Serial Monitor** (set baud rate to **115200**) to see the "WiFi Connected" and "Firebase" messages!
