# Aura Fit 🧘‍♂️💓

> **A premium fitness & health companion app powered by ESP32 & Flutter.**

Aura Fit is a cutting-edge health monitoring system that bridges the gap between raw hardware data and a beautiful, high-performance mobile interface. It reads real-time biometric data from a custom ESP32 wearable and visualizes it with a sleek, dark-themed UI.

## ✨ Features

-   **Deep Dark UI:** A premium aesthetic with neon cyan and vibrant purple accents.
-   **Real-time BLE:** Seamless Bluetooth Low Energy streaming with low latency.
-   **Smart Vitals:** 
    -   **BPM Calculation:** Dynamic heart rate tracking.
    -   **Stress Analysis:** Algorithmic interpretation of heart rate variability.
    -   **Anxiety Status:** Instant feedback on your mental state (Calm, Elevated, High).
-   **Live Charting:** Smooth, hardware-accelerated graphing of raw sensor data.
-   **Cross-Platform:** Runs on **Android**, **iOS**, and **Web (Chrome)**.

## 🛠️ Hardware Stack

-   **Microcontroller:** ESP32 (Dev Kit V1 recommended)
-   **Sensors:** Analog Pulse Sensor (e.g., KEYES/Ky-039 or generic PPG)
-   **Feedback:** 
    -   Active Piezo Buzzer
    -   Red LED Indicator

## 🚀 Getting Started

### 1. Firmware (ESP32)
Flash the provided firmware to your ESP32.
-   **File:** `aurafit_firmware.ino`
-   **Pinout:**
    -   `GPIO 32`: Pulse Sensor (Analog)
    -   `GPIO 10`: Buzzer
    -   `GPIO 4`: LED

### 2. Mobile App (Flutter)
1.  **Clone/Open** the `aurafit` project.
2.  **Install dependencies:** `flutter pub get`
3.  **Run:** `flutter run`

## 📦 Dependencies

-   `flutter_blue_plus`: Bluetooth Low Energy management.
-   `provider`: Efficient state management.
-   `fl_chart`: High-performance charting.
-   `google_fonts`: Premium typography (Outfit).
-   `percent_indicator`: Visual data representation.

---
*Built with 💙 by Aura Fit Team*
