#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>
#include <ESP8266HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>
#include <NTPClient.h>
#include "secrets.h"

// --- Pins ---
#define SOIL_PIN A0
#define PUMP_PIN D2

// --- Variables ---
int soil1 = 0;
int soil2 = 0;
bool pumpStatus = false;

// --- Timers ---
unsigned long previousMillis = 0;
// const long interval = 500; // OLD: 500ms
const long interval = 900000; // NEW: 15 Minutes (15 * 60 * 1000)

unsigned long previousHeartbeatMillis = 0;
const long heartbeatInterval = 30000; // 30 Seconds

unsigned long previousScheduleMillis = 0;
const long scheduleInterval = 60000; // Check every 1 minute
 
 // --- Auto-Lock / Cooldown Variables ---
 unsigned long manualPumpStartTime = 0;
 unsigned long lastPumpOffTime = 0;
 const long MAX_PUMP_RUNTIME = 15000; // 15 Seconds Max Run
 const long PUMP_COOLDOWN = 5000;     // 5 Seconds Cooldown

// --- Objects ---
WiFiClientSecure client;
HTTPClient http;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 0); // UTC offset 0, handle timezone in App or add offset here if needed

// --- Helper: Connect to WiFi ---
void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  
  client.setInsecure();
}

// --- Helper: DB Read ---
String dbRead(String path) {
  if (WiFi.status() != WL_CONNECTED) return "null";
  String url = String(DB_URL) + path + ".json?auth=" + DB_SECRET;
  http.begin(client, url);
  int code = http.GET();
  String payload = (code == 200) ? http.getString() : "null";
  http.end();
  return payload;
}

// --- Helper: DB Write ---
void dbWrite(String path, String value) {
  if (WiFi.status() != WL_CONNECTED) return;
  String url = String(DB_URL) + path + ".json?auth=" + DB_SECRET;
  http.begin(client, url);
  http.PUT(value);
  http.end();
}

void sendHeartbeat() {
  String ts = String(timeClient.getEpochTime());
  long rssi = WiFi.RSSI();
  Serial.println("Sending Heartbeat...");
  dbWrite("/device/status", "{\"timestamp\":" + ts + ",\"rssi\":" + String(rssi) + "}");
}

void takeReading() {
    soil1 = analogRead(SOIL_PIN);
    soil2 = map(soil1, 0, 1023, 0, 100);

    Serial.print("Reading: "); Serial.println(soil1);

    // Auto Logic
    if (soil1 < 270) {
      // NOTE: Buck Converter / Standard Relay logic (HIGH = ON)
      digitalWrite(PUMP_PIN, HIGH);
      pumpStatus = true;
      Serial.println("Action: PUMP ON (Low Water)");
      delay(10000); 
      digitalWrite(PUMP_PIN, LOW);
      pumpStatus = false;
      
      dbWrite("/status/last_watered", String(timeClient.getEpochTime()));
    } else {
      digitalWrite(PUMP_PIN, LOW);
      Serial.println("Action: PUMP OFF (Enough Water)");
      pumpStatus = false;
    }
    
    // Update One-Time Status
    String json = "{";
    json += "\"raw\":" + String(soil1) + ",";
    json += "\"mapped\":" + String(soil2) + ",";
    json += "\"pump\":" + String(pumpStatus ? "true" : "false");
    json += "}";
    dbWrite("/status/sensors", json);

    // --- NEW: HISTORY LOGGING ---
    String hJson = "{";
    hJson += "\"t\":" + String(timeClient.getEpochTime()) + ","; // Time
    hJson += "\"m\":" + String(soil2) + ",";                     // Moisture
    hJson += "\"p\":" + String(pumpStatus ? 1 : 0);              // Pump (0/1)
    hJson += "}";
    
    // Path: /history/log/<timestamp>
    dbWrite("/history/log/" + String(timeClient.getEpochTime()), hJson);
}

void setup() {
  pinMode(SOIL_PIN, INPUT);
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, LOW); // Start OFF (Low)
  
  Serial.begin(115200);
  Serial.println("Booting (BUCK CONVERTER VERSION)");

  setupWifi();
  timeClient.begin();
  timeClient.setTimeOffset(19800); // FIXED: Set to IST (UTC + 5:30)

  // OTA Setup
  ArduinoOTA.setHostname("SoilSensor-OTA");
  ArduinoOTA.onStart([]() { Serial.println("Start updating"); });
  ArduinoOTA.onEnd([]() { Serial.println("\nEnd"); });
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  ArduinoOTA.onError([](ota_error_t error) { Serial.printf("Error[%u]: ", error); });
  ArduinoOTA.begin();
  
  Serial.println("Ready");
  
  // --- IMMEDIATE FIRST RUN ---
  Serial.println("Performing initial reading...");
  timeClient.update();
  sendHeartbeat();
  sendHeartbeat();
  takeReading();
}

void checkManualPump() {
  String payload = dbRead("/control/pump");
  unsigned long currentMillis = millis();

  // Case 1: App requests ON
  if (payload == "true") {
    // Check Cooldown: If we recently turned off, don't allow ON yet
    if (!pumpStatus && (currentMillis - lastPumpOffTime < PUMP_COOLDOWN)) {
       Serial.println("Cooldown active. Ignoring ON request.");
       // Optional: Force switch back to false in DB so UI reflects reality
       dbWrite("/control/pump", "false"); 
       return; 
    }

    // If not already ON, mark start time
    if (!pumpStatus) {
       // BUCK: HIGH = ON
       digitalWrite(PUMP_PIN, HIGH);
       pumpStatus = true;
       manualPumpStartTime = currentMillis;
       Serial.println("Manual Pump ON");
    } 
    // If already ON, check Max Runtime
    else {
       if (currentMillis - manualPumpStartTime > MAX_PUMP_RUNTIME) {
          Serial.println("Auto-Lock: Max runtime exceeded. Turning OFF.");
          // BUCK: LOW = OFF
          digitalWrite(PUMP_PIN, LOW);
          pumpStatus = false;
          lastPumpOffTime = currentMillis;
          dbWrite("/control/pump", "false"); // Sync UI
       }
    }
  } 
  // Case 2: App requests OFF
  else if (payload == "false") {
    if (pumpStatus) {
       // BUCK: LOW = OFF
       digitalWrite(PUMP_PIN, LOW);
       pumpStatus = false;
       lastPumpOffTime = currentMillis; // Start cooldown
       Serial.println("Manual Pump OFF");
       
       // Update Last Watered Time
       dbWrite("/status/last_watered", String(timeClient.getEpochTime()));
    }
  }
}

// NEW: Track last watered minute to prevent double-watering
int lastTriggeredMinute = -1;

void checkSchedule() {
  // Force update to ensure fresh time
  timeClient.update();
  
  int currentH = timeClient.getHours();
  int currentM = timeClient.getMinutes();
  int currentS = timeClient.getSeconds(); 
  
  // Optimization: If we already watered this minute, skip checking to save DB reads/Pump logic
  if (currentM == lastTriggeredMinute) {
      return; 
  }

  String timeStr = (currentH < 10 ? "0" : "") + String(currentH) + ":" + (currentM < 10 ? "0" : "") + String(currentM);
  
  // Debug Time
  Serial.print("Current Time (IST): ");
  Serial.print(timeStr);
  Serial.print(":");
  Serial.println(currentS);
  
  String payload = dbRead("/config/scheduler/slots"); 
  
  Serial.print("Looking for: "); Serial.print(timeStr);
  Serial.print(" in Payload: "); Serial.println(payload);

  int index = payload.indexOf(timeStr);
  if (index >= 0) {
     int duration = 5; // Default 5s
     if (payload.charAt(index + 5) == '|') {
        int endQuote = payload.indexOf('"', index + 5);
        if (endQuote > 0) {
           String durStr = payload.substring(index + 6, endQuote);
           duration = durStr.toInt();
        }
     }
  
     Serial.printf("MATCH! Watering for %d sec\n", duration);
     // BUCK: HIGH = ON
     digitalWrite(PUMP_PIN, HIGH);
     
     // Update flag BEFORE delay so we don't retry if delay is short
     lastTriggeredMinute = currentM;
     
     delay(duration * 1000); 
     // BUCK: LOW = OFF
     digitalWrite(PUMP_PIN, LOW);
     
     dbWrite("/status/last_watered", String(timeClient.getEpochTime()));
  } else {
     Serial.println("No Schedule Match.");
  }
}

void loop() {
  ArduinoOTA.handle();
  timeClient.update();
  unsigned long currentMillis = millis();

  // 0. Manual Pump Check (Every 1s for responsiveness)
  static unsigned long previousManualMillis = 0;
  if (currentMillis - previousManualMillis >= 1000) {
    previousManualMillis = currentMillis;
    checkManualPump(); 
  }

  // 1. Heartbeat (Every 30s)
  if (currentMillis - previousHeartbeatMillis >= heartbeatInterval) {
    previousHeartbeatMillis = currentMillis;
    sendHeartbeat();
  }

  // 2. Sensor Reading (Every 3 Hours)
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    takeReading();
  }
  
  // 3. Schedule Check (Every 1 Minute)
  if (currentMillis - previousScheduleMillis >= scheduleInterval) {
     previousScheduleMillis = currentMillis;
     checkSchedule();
  }
}
