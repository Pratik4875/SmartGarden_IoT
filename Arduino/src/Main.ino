/* ===========================================================
   SMART GARDEN - FIRMWARE V1.5 (SECURE)
   
   Updates:
   1. SECURED: Credentials moved to secrets.h
   2. FIXED: Safety Timer calculation uses fresh millis()
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

// IMPORT SECRETS
#include "secrets.h" 

// ---------------- PIN MAP ----------------
#define RELAY_PIN    D1     // LOW = ON (Open Drain)
#define DHT_PIN      D2
#define DHT_TYPE     DHT11
#define SOIL_POWER   D6
#define SOIL_PIN     A0

// ---------------- TIMING ----------------
#define POLL_INTERVAL_MS 500     
#define SENSOR_INTERVAL_MS 10000 
#define HARD_LIMIT_SEC 2000      

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

// ---------------- HELPERS ----------------

void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleepMode(WIFI_NONE_SLEEP); // Keep Power Bank Awake
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
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
  String payload = "null";
  if(code == 200) {
    payload = http.getString();
  }
  http.end();
  return payload;
}

// ---------------- HARDWARE CONTROL ----------------

void pumpON() {
  if(isPumpRunning) return;
  
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // ON
  
  isPumpRunning = true;
  pumpStartTime = millis(); 
  
  Serial.println(">>> PUMP ON");
  dbWrite("/status/pump_active", "true");
}

void pumpOFF(String reason) {
  if(!isPumpRunning && reason != "BOOT") return;
  
  pinMode(RELAY_PIN, INPUT); // OFF
  
  isPumpRunning = false;
  Serial.printf(">>> PUMP OFF [%s]\n", reason.c_str());
  
  dbWrite("/status/pump_active", "false");
  dbWrite("/control/pump", "false"); 
  
  String ts = String(timeClient.getEpochTime());
  dbWrite("/status/last_watered", ts);
}

// ---------------- SENSORS ----------------

void readSensors() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  
  digitalWrite(SOIL_POWER, HIGH);
  delay(100);
  int raw = analogRead(SOIL_PIN);
  digitalWrite(SOIL_POWER, LOW);
  
  int percent = map(raw, 1024, 300, 0, 100); 
  if(percent < 0) percent = 0;
  if(percent > 100) percent = 100;

  if(!isnan(t)) {
    String json = "{\"temp\":" + String(t) + ",\"humidity\":" + String(h) + "}";
    dbWrite("/sensors/dht", json);
  }
  
  String soilJson = "{\"raw\":" + String(raw) + ",\"percent\":" + String(percent) + "}";
  dbWrite("/sensors/soil", soilJson);

  long rssi = WiFi.RSSI();
  String ip = WiFi.localIP().toString();
  String devJson = "{\"ip\":\"" + ip + "\",\"rssi\":" + String(rssi) + ",\"ver\":\"1.5-SECURE\"}";
  dbWrite("/device", devJson);
}

// ---------------- MAIN ----------------

void setup() {
  Serial.begin(115200);
  delay(2000); 
  
  Serial.println("\n\n=== SYSTEM BOOT v1.5 (SECURE) ===");
  pinMode(SOIL_POWER, OUTPUT);
  pinMode(RELAY_PIN, INPUT); 
  
  dht.begin();
  setupWifi();
  
  timeClient.begin();
  timeClient.update();
  
  ArduinoOTA.setHostname("SmartGardenESP");
  ArduinoOTA.begin();

  pumpOFF("BOOT");
}

void loop() {
  ArduinoOTA.handle();
  timeClient.update();
  unsigned long now = millis();

  // 1. Check Pump Command
  if (now - lastPoll > POLL_INTERVAL_MS) {
    lastPoll = now;
    String cmd = dbRead("/control/pump");
    if (cmd == "true") {
      pumpON();
    } else if (cmd == "false") {
      pumpOFF("MANUAL");
    }
  }

  // 2. Safety Cutoff
  if (isPumpRunning) {
    unsigned long limit = (unsigned long)HARD_LIMIT_SEC * 1000UL;
    unsigned long elapsed = millis() - pumpStartTime; 

    if (now - lastDebugPrint > 1000) {
       lastDebugPrint = now;
       Serial.printf("Timer: %lu ms / %lu ms\n", elapsed, limit);
    }

    if (elapsed > limit) {
      Serial.printf("LIMIT REACHED: %lu > %lu\n", elapsed, limit);
      pumpOFF("SAFETY");
    }
  }

  // 3. Read Sensors
  if (now - lastSensor > SENSOR_INTERVAL_MS) {
    lastSensor = now;
    readSensors();
  }
}