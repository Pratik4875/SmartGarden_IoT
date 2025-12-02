/* ===========================================================
   SMART GARDEN - FIRMWARE V2.3 (SECURE + LOGGER)
   
   Updates:
   1. SECURE: Uses ?auth=DB_SECRET to bypass locked rules.
   2. LOGGING: Pushes data to '/history' every 60 minutes.
   3. UNIFIED: Keeps all v2.1 logic (Sync, Manual, Auto).
   ===========================================================
*/

#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

#include "secrets.h" 

#define RELAY_PIN    D1
#define DHT_PIN      D2
#define DHT_TYPE     DHT11
#define SOIL_POWER   D6
#define SOIL_PIN     A0

// ---------------- TIMING ----------------
#define POLL_INTERVAL_MS 200     
#define SENSOR_INTERVAL_MS 10000 
#define HISTORY_INTERVAL_MS 3600000 // 1 Hour (60 * 60 * 1000)

// ---------------- OBJECTS ----------------
DHT dht(DHT_PIN, DHT_TYPE);
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0);
WiFiClientSecure client;
HTTPClient http;

// ---------------- VARIABLES ----------------
unsigned long lastPoll = 0;
unsigned long lastSensor = 0;
unsigned long lastHistoryLog = 0; // History Timer
unsigned long lastDebugPrint = 0;
unsigned long pumpStartTime = 0;
bool isPumpRunning = false;
int lastScheduledMinute = -1;

unsigned long currentDurationLimit = 5000;

// ---------------- HELPERS (SECURE) ----------------
void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleepMode(WIFI_NONE_SLEEP); // Keep Power Bank Alive
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\nWiFi Connected");
  client.setInsecure(); 
}

// Write (Overwrite) - uses DB_SECRET
void dbWrite(String path, String value) {
  String url = String(DB_URL) + path + ".json?auth=" + DB_SECRET;
  http.begin(client, url);
  http.PUT(value);
  http.end();
}

// Push (Add to list) - uses DB_SECRET
void dbPush(String path, String value) {
  String url = String(DB_URL) + path + ".json?auth=" + DB_SECRET;
  http.begin(client, url);
  http.POST(value); // POST creates a unique ID (history log)
  http.end();
}

// Read - uses DB_SECRET
String dbRead(String path) {
  String url = String(DB_URL) + path + ".json?auth=" + DB_SECRET;
  http.begin(client, url);
  int code = http.GET();
  if(code == 200) return http.getString();
  return "null";
}

// ---------------- LOGIC ----------------

int getDuration() {
  String durStr = dbRead("/config/scheduler/duration_sec");
  int val = (durStr != "null") ? durStr.toInt() : 5;
  if (val <= 0) val = 5; 
  return val;
}

void startPumpLogic(String source) {
  if (isPumpRunning) return;

  int duration = getDuration();
  currentDurationLimit = duration * 1000UL;

  Serial.printf(">>> STARTING PUMP [%s] for %d seconds\n", source.c_str(), duration);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // ON
  isPumpRunning = true;
  pumpStartTime = millis();
  
  dbWrite("/status/pump_active", "true");
  
  // Sync the switch to TRUE so the loop doesn't kill it
  if (source == "AUTO_SCHEDULE") dbWrite("/control/pump", "true");
}

void stopPumpLogic(String reason) {
  if (!isPumpRunning && reason != "BOOT") return;

  Serial.printf(">>> STOPPING PUMP [%s]\n", reason.c_str());
  pinMode(RELAY_PIN, INPUT); // OFF
  isPumpRunning = false;

  dbWrite("/status/pump_active", "false");
  dbWrite("/control/pump", "false"); 
  dbWrite("/status/last_watered", String(timeClient.getEpochTime()));
}

void checkSchedule() {
  int currentH = timeClient.getHours();
  int currentM = timeClient.getMinutes();
  
  if (currentM == lastScheduledMinute) return;

  String enabled = dbRead("/config/scheduler/enabled");
  if (enabled != "true") return;

  String targetTime = dbRead("/config/scheduler/time_utc"); 
  if (targetTime.length() < 5) return;

  int targetH = targetTime.substring(1, 3).toInt();
  int targetM = targetTime.substring(4, 6).toInt();

  if (currentH == targetH && currentM == targetM) {
    lastScheduledMinute = currentM; 
    startPumpLogic("AUTO_SCHEDULE");
  }
}

// ---------------- SENSORS & LOGGING ----------------

void readSensors(bool forceLog) {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  
  digitalWrite(SOIL_POWER, HIGH); delay(100);
  int raw = analogRead(SOIL_PIN); digitalWrite(SOIL_POWER, LOW);
  int percent = map(raw, 1024, 300, 0, 100); 
  if(percent < 0) percent = 0; if(percent > 100) percent = 100;

  // 1. Realtime Update (Overwrite)
  if(!isnan(t)) dbWrite("/sensors/dht", "{\"temp\":" + String(t) + ",\"humidity\":" + String(h) + "}");
  dbWrite("/sensors/soil", "{\"raw\":" + String(raw) + ",\"percent\":" + String(percent) + "}");
  
  long rssi = WiFi.RSSI();
  String ip = WiFi.localIP().toString();
  dbWrite("/device", "{\"ip\":\"" + ip + "\",\"rssi\":" + String(rssi) + ",\"ver\":\"2.3-SECURE\"}");

  // 2. History Log (Push) - Runs every hour
  if (forceLog) {
    unsigned long ts = timeClient.getEpochTime();
    // Structure: { "ts": 17123456, "t": 25.5, "h": 60, "s": 45 }
    String logJson = "{\"ts\":" + String(ts) + 
                     ",\"t\":" + String(t) + 
                     ",\"h\":" + String(h) + 
                     ",\"s\":" + String(percent) + "}";
    
    Serial.println(">>> LOGGING HISTORY: " + logJson);
    dbPush("/history", logJson);
  }
}

// ---------------- MAIN ----------------

void setup() {
  Serial.begin(115200);
  delay(1000); 
  pinMode(SOIL_POWER, OUTPUT);
  pinMode(RELAY_PIN, INPUT); 
  dht.begin();
  setupWifi();
  timeClient.begin();
  ArduinoOTA.setHostname("SmartGardenESP");
  ArduinoOTA.begin();
  
  stopPumpLogic("BOOT");
}

void loop() {
  ArduinoOTA.handle();
  timeClient.update();
  unsigned long now = millis();

  // 1. FAST POLL
  if (now - lastPoll > POLL_INTERVAL_MS) {
    lastPoll = now;
    String cmd = dbRead("/control/pump");
    if (cmd == "true") { if (!isPumpRunning) startPumpLogic("MANUAL"); } 
    else if (cmd == "false" && isPumpRunning) { stopPumpLogic("MANUAL"); }
    if (!isPumpRunning) checkSchedule();
  }

  // 2. SAFETY TIMER
  if (isPumpRunning) {
    unsigned long elapsed = millis() - pumpStartTime; 
    if (elapsed > currentDurationLimit) stopPumpLogic("SAFETY");
  }

  // 3. SENSORS (Realtime every 10s)
  if (now - lastSensor > SENSOR_INTERVAL_MS) {
    lastSensor = now;
    // Check if we also need to log history (Every 1 Hour)
    bool shouldLog = (now - lastHistoryLog > HISTORY_INTERVAL_MS);
    if (shouldLog) lastHistoryLog = now;
    
    readSensors(shouldLog);
  }
}