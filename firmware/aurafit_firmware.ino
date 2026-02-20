#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>


// -------------------------------------------------------------------------
// HARDWARE CONFIGURATION
// -------------------------------------------------------------------------
// NOTE: GPIO 10 is often connected to the ESP32's internal SPI Flash memory.
// If your board fails to boot or crashes, PLEASE CHANGE THE BUZZER PIN (e.g.,
// to 5, 18, or 19).
#define SENSOR_PIN 32 // Analog Input (ADC1_CH4)
#define BUZZER_PIN 10 // Piezo Buzzer
#define LED_PIN 4     // Red Beat LED

// BLE UUIDs (Must match Flutter App)
#define SERVICE_UUID "180D"
#define CHARACTERISTIC_UUID "2A37"

// -------------------------------------------------------------------------
// GLOBAL VARIABLES
// -------------------------------------------------------------------------
BLEServer *pServer = NULL;
BLECharacteristic *pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Beat Detection Variables
int threshold = 2050; // Center point for 3.3V ADC (0-4095)
int signalMax = 0;
int signalMin = 4096;
unsigned long lastBeatTime = 0;
int bpm = 0;
int ibi = 600; // Inter-Beat Interval (mS)
bool pulseDetected = false;

// Loop Timing
unsigned long lastSampleTime = 0;
const unsigned long sampleInterval = 20; // 50Hz Sampling (20ms)

class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) { deviceConnected = true; };

  void onDisconnect(BLEServer *pServer) { deviceConnected = false; }
};

void setup() {
  Serial.begin(115200);

  // Hardware Setup
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(SENSOR_PIN, INPUT);

  // Initial State
  digitalWrite(LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);

  // BLE Setup
  BLEDevice::init("Aura_Fit_BLE");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);

  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();

  Serial.println("Aura Fit BLE Ready. Waiting for connection...");
}

void loop() {
  unsigned long currentMillis = millis();

  // Sampling Loop (50Hz)
  if (currentMillis - lastSampleTime >= sampleInterval) {
    lastSampleTime = currentMillis;

    // 1. Read Sensor
    int rawValue = analogRead(SENSOR_PIN);

    // 2. Beat Detection Algorithm (Simple Threshold for reliable detection)
    // Dynamic Threshold Logic:
    // If signal is high
    if (rawValue > threshold && rawValue > signalMax) {
      signalMax = rawValue;
    }
    // If signal is low
    if (rawValue < threshold && rawValue < signalMin) {
      signalMin = rawValue;
    }

    // Check for Beat
    // (Value crossed threshold going up AND enough time passed since last beat)
    if (rawValue > threshold && !pulseDetected &&
        (currentMillis - lastBeatTime > 250)) {
      pulseDetected = true;

      // Calculate BPM
      unsigned long delta = currentMillis - lastBeatTime;
      lastBeatTime = currentMillis;
      bpm = 60000 / delta;

      // Filter unrealistic BPMs
      if (bpm < 30 || bpm > 220) {
        // Ignore or reset
      } else {
        // Valid Beat Action
        triggerBeatFeedback();
      }
    }

    // Reset Pulse Detection on falling edge
    if (rawValue < threshold && pulseDetected) {
      pulseDetected = false;
      // Adjust threshold slowly to track the DC offset
      threshold = (signalMin + signalMax) / 2;
      // Reset min/max for next window?
      // A simple decay is better for continuous tracking
      signalMax -= 2;
      signalMin += 2;
    }

    // Decay mechanism for dynamic thresholding if no beats found
    if (currentMillis - lastBeatTime > 2000) {
      threshold = 2050; // Reset to center
      signalMax = 2500;
      signalMin = 1500;
      bpm = 0; // No finger?
    }

    // 3. Send Data over BLE
    if (deviceConnected) {
      char dataString[32];
      // Format: "BPM:75,RAW:2150"
      sprintf(dataString, "BPM:%d,RAW:%d", bpm, rawValue);

      pCharacteristic->setValue(dataString);
      pCharacteristic->notify();
    }
  }

  // BLE Maintenance
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
}

void triggerBeatFeedback() {
  // LED
  digitalWrite(LED_PIN, HIGH);

  // Buzzer (Short Beep)
  // Note: tone() is not always available on all ESP32 cores,
  // but a simple HIGH/LOW loop or ledc works.
  // Using simple HIGH pulse for active buzzer.
  digitalWrite(BUZZER_PIN, HIGH);

  // Non-blocking delay substitute?
  // For a short beep inside a 20ms loop, a tiny delay(10) is acceptable
  // or use a timestamp to turn off in main loop.
  // For simplicity here, we'll block briefly (10ms) which won't hurt BLE much.
  delay(10);

  digitalWrite(LED_PIN, LOW);
  digitalWrite(BUZZER_PIN, LOW);
}
