# Sprint Timer — BLE Timing App

A professional sprint/athletics timing Android app that receives data from a homemade BLE timing chip.

---

## 📱 Features

- **Live BLE timing** — receives START, SPLIT, FINISH events from your chip
- **Session management** — create and organize timing sessions by distance, location, date
- **Athlete management** — register athletes with names, bib numbers, and categories
- **Real-time display** — large time display with glow animation on new times
- **Stats** — best, average, worst times per session
- **CSV export** — share results via email/Drive/etc.
- **Simulator mode** — test the app without hardware
- **SQLite persistence** — all data saved locally

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Android Studio or VS Code with Flutter extension
- Android device with BLE support (Android 6.0+)

### Install & Run

```bash
git clone <this-repo>
cd sprint_timer
flutter pub get
flutter run
```

### Fonts
Download **Space Mono** from Google Fonts and place the TTF files in `fonts/`:
```
fonts/
  SpaceMono-Regular.ttf
  SpaceMono-Bold.ttf
```

Or remove the font references from `pubspec.yaml` to use the system font.

---

## 📡 BLE Protocol

### UUIDs (configure in `lib/services/ble_service.dart`)
```
Service UUID:        0000ABCD-0000-1000-8000-00805F9B34FB
Characteristic UUID: 0000ABCE-0000-1000-8000-00805F9B34FB
```
Change these to match your chip's firmware.

### Packet Format (8 bytes)

| Byte | Field     | Description                              |
|------|-----------|------------------------------------------|
| 0    | Event     | Event type (see below)                   |
| 1    | Lane      | Lane number (1–8)                        |
| 2–5  | Timestamp | Milliseconds (big-endian uint32)         |
| 6    | Sequence  | Rolling counter (0–255)                  |
| 7    | Checksum  | XOR of bytes 0–6                         |

### Event Types

| Code | Event     | Description                                |
|------|-----------|--------------------------------------------|
| 0x01 | START     | Athlete left the start gate                |
| 0x02 | SPLIT     | Intermediate gate triggered                |
| 0x03 | FINISH    | Athlete crossed finish line                |
| 0xFF | HEARTBEAT | Keep-alive packet (chip is still alive)    |

### Time Calculation

**With explicit START:**
```
durationMs = FINISH.timestamp - START.timestamp
```

**Without START (chip already measures from trigger):**
```
durationMs = FINISH.timestamp (chip-measured elapsed time)
```

### Checksum
Simple XOR of bytes 0–6:
```cpp
// Arduino/ESP32 example
uint8_t checksum = 0;
for (int i = 0; i < 7; i++) checksum ^= packet[i];
packet[7] = checksum;
```

---

## 🔧 Firmware Integration (ESP32/Arduino sketch skeleton)

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID     "0000ABCD-0000-1000-8000-00805F9B34FB"
#define CHAR_UUID        "0000ABCE-0000-1000-8000-00805F9B34FB"

BLEServer* pServer = NULL;
BLECharacteristic* pChar = NULL;
bool deviceConnected = false;

void sendTimingEvent(uint8_t eventType, uint8_t lane, uint32_t timestampMs, uint8_t seq) {
  uint8_t packet[8];
  packet[0] = eventType;
  packet[1] = lane;
  packet[2] = (timestampMs >> 24) & 0xFF;
  packet[3] = (timestampMs >> 16) & 0xFF;
  packet[4] = (timestampMs >> 8) & 0xFF;
  packet[5] = timestampMs & 0xFF;
  packet[6] = seq;
  // Checksum
  uint8_t crc = 0;
  for (int i = 0; i < 7; i++) crc ^= packet[i];
  packet[7] = crc;

  if (deviceConnected) {
    pChar->setValue(packet, 8);
    pChar->notify();
  }
}

void setup() {
  BLEDevice::init("SprintTimer-1");
  pServer = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);
  pChar = pService->createCharacteristic(CHAR_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pChar->addDescriptor(new BLE2902());
  pService->start();
  BLEAdvertising* pAdv = BLEDevice::getAdvertising();
  pAdv->addServiceUUID(SERVICE_UUID);
  pAdv->start();
}

void loop() {
  // Your start/finish detection logic here
  // When athlete triggers start gate:
  //   sendTimingEvent(0x01, lane, millis(), seq++);
  // When athlete crosses finish:
  //   sendTimingEvent(0x03, lane, millis(), seq++);
  delay(10);
}
```

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/
│   ├── athlete.dart            # Athlete data model
│   ├── ble_packet.dart         # BLE protocol parser
│   ├── time_record.dart        # Individual timing record
│   └── timing_session.dart     # Session with records
├── services/
│   ├── ble_service.dart        # BLE scan/connect/receive
│   ├── database_service.dart   # SQLite persistence
│   ├── export_service.dart     # CSV export
│   └── session_service.dart    # Session & timing logic
├── screens/
│   ├── home_screen.dart        # Bottom nav shell
│   ├── timing_screen.dart      # Main timing UI
│   ├── sessions_screen.dart    # Session list
│   ├── session_detail_screen.dart # Session results
│   ├── athletes_screen.dart    # Athlete management
│   ├── ble_scan_screen.dart    # BLE device picker
│   └── settings_screen.dart   # App settings
├── widgets/
│   ├── time_card.dart          # Individual time display
│   ├── connection_badge.dart   # BLE status indicator
│   ├── session_picker_sheet.dart # Session selector
│   └── new_session_sheet.dart  # Create session form
└── utils/
    ├── app_theme.dart          # Colors and theme
    └── time_formatter.dart     # Time formatting utilities
```

---

## 🎛️ Customization

| What | Where |
|------|-------|
| BLE UUIDs | `lib/services/ble_service.dart` — top constants |
| Device name filter | `lib/services/ble_service.dart` — `kDeviceNamePrefix` |
| Packet format | `lib/models/ble_packet.dart` — `parse()` method |
| Colors | `lib/utils/app_theme.dart` |
| Time precision | Uses ms throughout; display in `time_formatter.dart` |

---

## 🧪 Testing Without Hardware

1. Open the app and go to **Connect Chip** (BLE icon in bottom bar)
2. Tap **Enable Simulator**
3. Go back to the Timer screen
4. Create a session and tap **START**
5. Use the **SIM START** and **SIM FINISH** buttons to generate fake events

---

## 📄 License

MIT — use freely for personal and commercial projects.
