#include <WiFi.h>
#include <WiFiManager.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>
#include <TinyGPSPlus.h>
#include <HardwareSerial.h>
#include <time.h>

// Provide the token generation process info
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions
#include "addons/RTDBHelper.h"

/* --- Credentials --- */
#define API_KEY "AIzaSyBHseBqlTJWVVIOhrKxK9-q0Lt4DRuoDmI"
#define DATABASE_URL "https://protega-app-2026-62ec2-default-rtdb.firebaseio.com/"

/* --- Hardware Pins --- */
#define SOS_PIN 4
#define GPS_TX_PIN 16 // Connects to GPS RX (Neo 6m RX -> G16)
#define GPS_RX_PIN 17 // Connects to GPS TX (Neo 6m TX -> G17)
#define I2C_SDA 21
#define I2C_SCL 22
#define BATTERY_PIN 34 // Analog pin for reading battery


/* --- Global Objects --- */
FirebaseData fbdo;
FirebaseData streamData;
FirebaseAuth auth;
FirebaseConfig config;
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);
TinyGPSPlus gps;
HardwareSerial gpsSerial(2);

/* --- State Variables --- */
String deviceId;
String alertStatus = "Normal";
unsigned long lastUpdateMillis = 0;
const unsigned long UPDATE_INTERVAL_MS = 10000;

/* --- Fall Detection States --- */
enum FallState { NORMAL_STATE, FREEFALL, IMPACT, INACTIVITY };
FallState fallState = NORMAL_STATE;
unsigned long fallStateTimer = 0;

/* --- Function Prototypes --- */
void pushToFirebase();
void processFallDetection();
void streamCallback(FirebaseStream data);
void streamTimeoutCallback(bool timeout);

void setup() {
  Serial.begin(115200);
  
  // GPS Initialization moved to the end of setup() to avoid buffer overflow during WiFi blocking
  
  // 2. Initialize Pins
  pinMode(SOS_PIN, INPUT_PULLUP);
  pinMode(BATTERY_PIN, INPUT);
  
  // 3. Initialize I2C for ADXL345
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setTimeOut(250000);
  if (!accel.begin()) {
    Serial.println("No ADXL345 detected! Check wiring.");
  } else {
    accel.setRange(ADXL345_RANGE_16_G);
    Serial.println("ADXL345 Initialized.");
  }
  
  // 4. Connect to WiFi using WiFiManager
  WiFiManager wm;
  
  // autoConnect will try to connect to a saved WiFi network.
  // If it fails, it will start an AP named "Protega-Setup".
  bool res = wm.autoConnect("Protega-Setup");
  
  if (!res) {
    Serial.println("Failed to connect to WiFi and hit timeout");
    // Restart if we somehow fail so it can try again
    ESP.restart();
  } else {
    Serial.println("\nWiFi Connected.");
  }
  
  // Configure NTP for accurate Epoch time
  configTime(0, 0, "pool.ntp.org");

  // 5. Generate Unique Device ID from MAC Address
  deviceId = WiFi.macAddress();
  deviceId.replace(":", "");
  Serial.println("Device ID: " + deviceId);
  
  // 6. Initialize Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Sign up (Anonymous auth)
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase Auth Successful");
  } else {
    Serial.printf("Firebase Auth Error: %s\n", config.signer.signupError.message.c_str());
  }
  
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // 7. Initialize Remote Reset Listener
  String streamPath = "/devices/" + deviceId + "/alertStatus";
  if (!Firebase.RTDB.beginStream(&streamData, streamPath.c_str())) {
    Serial.printf("Stream begin error, %s\n", streamData.errorReason().c_str());
  }
  Firebase.RTDB.setStreamCallback(&streamData, streamCallback, streamTimeoutCallback);

  // Initialize GPS Serial (UART2) AFTER blocking operations to prevent buffer overflow
  gpsSerial.begin(9600, SERIAL_8N1, GPS_TX_PIN, GPS_RX_PIN);
  
  // Flush any stale buffer data accumulated during boot
  while(gpsSerial.available() > 0) {
    gpsSerial.read();
  }
}

void streamCallback(FirebaseStream data) {
  if (data.dataType() == "string") {
    String val = data.stringData();
    if (val == "Normal") {
      alertStatus = "Normal";
      fallState = NORMAL_STATE;
      Serial.println("Received Remote Reset! Resuming normal tracking.");
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("Stream timeout, resuming...");
  }
}

void loop() {
  // 1. Process GPS Data (Non-blocking)
  while (gpsSerial.available() > 0) {
    char c = gpsSerial.read();
    // Serial.write(c); // Optional debugging check
    gps.encode(c);
  }
  
  // 2. Check SOS Button (Non-blocking with debounce)
  static bool lastSosState = HIGH;
  static unsigned long lastDebounceTime = 0;
  bool currentSosState = digitalRead(SOS_PIN);
  
  if (currentSosState != lastSosState) {
    lastDebounceTime = millis();
  }
  
  if ((millis() - lastDebounceTime) > 50) { 
    if (currentSosState == LOW) {
      // Button is held LOW
      if (alertStatus != "SOS Pressed") {
        alertStatus = "SOS Pressed";
        Serial.println("SOS Button Pressed! Alerting immediately.");
        pushToFirebase();
      }
    }
  }
  lastSosState = currentSosState;
  
  // 3. Process Fall Detection Logic
  // Only detect falls if we are not already in an SOS or Fall state
  if (alertStatus == "Normal") {
    processFallDetection();
  }
  
  // 4. Standard Tracking (Every 10 seconds)
  if (millis() - lastUpdateMillis >= UPDATE_INTERVAL_MS) {
    lastUpdateMillis = millis();
    
    // As per requirements: "If no alert is active, update the latitude and longitude 
    // in Firebase every 10 seconds to keep the real-time map updated, keeping alertStatus as Normal."
    if (alertStatus == "Normal") {
      pushToFirebase();
    }
  }
}

void processFallDetection() {
  sensors_event_t event;
  accel.getEvent(&event);
  
  // Calculate total acceleration magnitude (in Gs)
  float xG = event.acceleration.x / SENSORS_GRAVITY_STANDARD;
  float yG = event.acceleration.y / SENSORS_GRAVITY_STANDARD;
  float zG = event.acceleration.z / SENSORS_GRAVITY_STANDARD;
  float magnitude = sqrt(xG * xG + yG * yG + zG * zG);
  
  unsigned long currentMillis = millis();
  
  switch (fallState) {
    case NORMAL_STATE:
      // Stage 1: Freefall detection (< 0.4G for a brief window)
      if (magnitude < 0.4) {
        fallState = FREEFALL;
        fallStateTimer = currentMillis;
      }
      break;
      
    case FREEFALL:
      // Stage 2: Impact Spike detection (> 2.5G)
      if (magnitude > 2.5) {
        fallState = IMPACT;
        fallStateTimer = currentMillis;
      } else if (currentMillis - fallStateTimer > 1000) {
        // Timeout if no impact occurs within 1 second of freefall
        fallState = NORMAL_STATE;
      }
      break;
      
    case IMPACT:
      // Stage 3: Inactivity detection (~1.0G, no movement immediately following impact)
      if (abs(magnitude - 1.0) < 0.3) {
        if (currentMillis - fallStateTimer > 2000) {
          // Inactive for 2 seconds after impact -> Validate Fall!
          alertStatus = "Fall Detected";
          Serial.println("Fall Detected! Alerting immediately.");
          pushToFirebase();
          
          fallState = NORMAL_STATE; // Reset physics state
        }
      } else {
        if (currentMillis - fallStateTimer > 4000) {
          // If 4 seconds pass and still moving heavily, cancel fall detection (false alarm)
          fallState = NORMAL_STATE; 
        } else {
          // Keep resetting the inactivity timer as long as movement continues
          fallStateTimer = currentMillis;
        }
      }
      break;
  }
}

void pushToFirebase() {
  if (Firebase.ready()) {
    FirebaseJson json;
    
    // Add GPS Coordinates
    if (gps.location.isValid()) {
      json.set("latitude", gps.location.lat());
      json.set("longitude", gps.location.lng());
    } else {
      json.set("latitude", 0.0);
      json.set("longitude", 0.0);
    }
    
    // Add Alert Status
    json.set("alertStatus", alertStatus);
    
    // Add Battery & Active State
    json.set("batteryPercentage", getBatteryPercentage());
    json.set("deviceActive", true);
    
    // Add Timestamp (Epoch time if NTP synced, else relative millis)
    time_t now;
    time(&now);
    if (now > 100000) { // If NTP has synced (epoch > 100000)
      json.set("timestamp", (double)now); 
    } else {
      json.set("timestamp", (double)millis());
    }
    
    // Construct dynamic path: /devices/{deviceId}/
    String path = "/devices/" + deviceId;
    
    // Push JSON payload using updateNode (HTTP PATCH) to respect child-level rules
    Serial.printf("Pushing to %s | Status: %s\n", path.c_str(), alertStatus.c_str());
    if (alertStatus != "Normal") {
      // Synchronous push for emergencies
      Firebase.RTDB.updateNode(&fbdo, path.c_str(), &json);
    } else {
      // Asynchronous push for regular intervals
      Firebase.RTDB.updateNodeAsync(&fbdo, path.c_str(), &json);
    }
  }
}

int getBatteryPercentage() {
  // Read analog value from battery pin (ESP32 ADC is 12-bit, 0-4095)
  // Assuming a simple voltage divider. Note: You will likely need to calibrate 
  // the map() function below based on the actual resistors the hardware person used!
  int rawValue = analogRead(BATTERY_PIN);
  
  // Example: mapping 0V to fully charged 4.2V (4095)
  // Change 4095 to the max raw value you get when the battery is at 100%
  int percentage = map(rawValue, 0, 4095, 0, 100);
  
  // Constrain between 0 and 100% just in case of spikes
  if (percentage < 0) percentage = 0;
  if (percentage > 100) percentage = 100;
  
  return percentage;
}
