/* ===========================================================
   SMART GARDEN - FIRMWARE V1.7 (SPEED & LIMIT)
   
   Updates:
   1. SPEED: Polls Firebase every 200ms (5x faster).
   2. SAFETY: Hard Limit set to 2 SECONDS (Testing Mode).
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

// ---------------- TIMING ADJUSTMENTS ----------------
#define POLL_INTERVAL_MS 200     // <--- ULTRA FAST RESPONSE (0.2s)
#define SENSOR_INTERVAL_MS 10000 
#define HARD_LIMIT_SEC 2         // <--- 2 SECONDS LIMIT (As requested)
#define AUTO_DURATION_SEC 3000      // Auto schedule also runs for 2s

// ---------------- OBJECTS ----------------
DHT dht(DHT_PIN, DHT_TYPE);
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0);
WiFiClientSecure client;
HTTPClient http;

// ---------------- VARIABLES ----------------
unsigned long lastPoll = 0;
unsigned long lastSensor = 0;
unsigned long lastDebugPrint = 0;
unsigned long pumpStartTime = 0;
bool isPumpRunning = false;
int lastScheduledMinute = -1;

// ---------------- HELPERS ----------------
void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleepMode(WIFI_NONE_SLEEP);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) { delay(500); }
  client.setInsecure(); 
}

void dbWrite(String path, String value) {
  String url = String(DB_URL) + path + ".json?auth=" + API_KEY;
  http.begin(client, url);
  http.PUT(value);
  http.end();
}

String dbRead(String path) {
  String url = String(DB_URL) + path + ".json?auth=" + API_KEY;
  http.begin(client, url);
  int code = http.GET();
  if(code == 200) return http.getString();
  return "null";
}

// ---------------- LOGIC ----------------

void pumpON(String source) {
  if(isPumpRunning) return;
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // ON
  isPumpRunning = true;
  pumpStartTime = millis(); 
  Serial.println(">>> PUMP ON [" + source + "]");
  dbWrite("/status/pump_active", "true");
}

void pumpOFF(String reason) {
  if(!isPumpRunning && reason != "BOOT") return;
  pinMode(RELAY_PIN, INPUT); // OFF
  isPumpRunning = false;
  Serial.printf(">>> PUMP OFF [%s]\n", reason.c_str());
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
    pumpON("AUTO_SCHEDULE");
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
  pumpOFF("BOOT");
}

void loop() {
  ArduinoOTA.handle();
  timeClient.update();
  unsigned long now = millis();

  // 1. FAST POLL
  if (now - lastPoll > POLL_INTERVAL_MS) {
    lastPoll = now;
    String cmd = dbRead("/control/pump");
    if (cmd == "true") pumpON("MANUAL");
    else if (cmd == "false" && isPumpRunning) pumpOFF("MANUAL");
    
    // Only check schedule if pump is OFF (save bandwidth)
    if (!isPumpRunning) checkSchedule();
  }

  // 2. Safety Cutoff
  if (isPumpRunning) {
    unsigned long limit = (unsigned long)HARD_LIMIT_SEC * 1000UL;
    unsigned long elapsed = millis() - pumpStartTime; 
    
    // Debug Timer every 0.5s
    if (now - lastDebugPrint > 500) {
       lastDebugPrint = now;
       Serial.printf("Timer: %lu / %lu ms\n", elapsed, limit);
    }

    if (elapsed > limit) pumpOFF("SAFETY");
  }

  // 3. Sensors
  if (now - lastSensor > SENSOR_INTERVAL_MS) {
    lastSensor = now;
    readSensors();
  }
}

void readSensors() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  digitalWrite(SOIL_POWER, HIGH); delay(100);
  int raw = analogRead(SOIL_PIN); digitalWrite(SOIL_POWER, LOW);
  int percent = map(raw, 1024, 300, 0, 100); 
  if(percent < 0) percent = 0; if(percent > 100) percent = 100;

  if(!isnan(t)) dbWrite("/sensors/dht", "{\"temp\":" + String(t) + ",\"humidity\":" + String(h) + "}");
  dbWrite("/sensors/soil", "{\"raw\":" + String(raw) + ",\"percent\":" + String(percent) + "}");
  
  long rssi = WiFi.RSSI();
  String ip = WiFi.localIP().toString();
  dbWrite("/device", "{\"ip\":\"" + ip + "\",\"rssi\":" + String(rssi) + ",\"ver\":\"1.7-FAST\"}");
}