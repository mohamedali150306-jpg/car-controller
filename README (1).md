# 🤖 RoboCar Controller — Flutter App

A complete mobile controller for your 4-wheel Bluetooth robot car.  
Matches the dark UI mockup: battery gauge, mode switcher, D-pad, sensor display, serial log, and save-path recorder.

---

## 📋 Features

| Feature | Description |
|---|---|
| **Bluetooth** | Pairs with HC-05 / HC-06 via Classic Bluetooth (RFCOMM) |
| **Manual Mode** | D-pad (hold to drive) + 9 speed levels |
| **Autonomous Mode** | Activates obstacle-avoidance on Arduino; live scan animation |
| **Auto-Parking Mode** | Sends park command; animated 4-phase progress stepper |
| **Save Path Mode** | Record a manual drive path, then loop-playback it automatically |
| **Battery Monitor** | Real-time % from Arduino |
| **Sensor Display** | Live Left / Front / Right ultrasonic distances (cm) |
| **Serial Log** | Last 20 TX/RX lines, colour-coded |

---

## 🗂️ Project Structure

```
lib/
├── main.dart               ← App entry, theme setup
├── app_theme.dart          ← All colours / ThemeData
├── bluetooth_service.dart  ← BT connection + serial parsing
├── home_screen.dart        ← Root screen (top bar + scroll view)
├── bt_picker_dialog.dart   ← Paired-device picker
├── battery_card.dart       ← Battery % bar
├── mode_card.dart          ← Manual / Autonomous / Auto-Park tabs
├── manual_control_card.dart← D-pad + speed panel + Save Path panel
├── autonomous_card.dart    ← Autonomous status + wave animation
├── parking_card.dart       ← Phase stepper + start button
├── savepath_card.dart      ← Record / Loop-play / Stop path card
├── sensor_card.dart        ← L / F / R ultrasonic cells
└── log_card.dart           ← Serial log display
```

---

## ⚡ Quick Start

### 1. Prerequisites
- Flutter SDK ≥ 3.0  `flutter --version`
- Android phone with Bluetooth (API 21+)
- HC-05 already **paired** in Android Settings → Bluetooth

### 2. Install & Run

```bash
cd robocar_app
flutter pub get
flutter run
```

### 3. Build APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📡 Arduino Communication Protocol

### App → Arduino (TX)

| Command | Meaning |
|---|---|
| `MODE:M\n` | Switch to Manual mode |
| `MODE:A\n` | Switch to Autonomous mode |
| `MODE:P\n` | Switch to Auto-Parking mode |
| `F<n>\n` | Move forward at speed n (1-9) e.g. `F4` |
| `B<n>\n` | Move backward at speed n |
| `L<n>\n` | Turn left at speed n |
| `R<n>\n` | Turn right at speed n |
| `S0\n` | Stop (sent on button release) |
| `SPD:<n>\n` | Speed level changed (1-9) |
| `K\n` | Start recording path |
| `E\n` | Stop recording and begin loop playback |
| `Q\n` | Stop path playback |

> **Speed → PWM mapping (9 levels):**  
> Level 1 = PWM 60, Level 2 = 88, ..., Level 9 = 255  
> Formula: `pwm = map(level, 1, 9, 60, 255)`

### Arduino → App (RX)

| Message | Meaning |
|---|---|
| `B:<pct>%\n` | Battery percentage e.g. `B:78%` |
| `SNS:<left>,<front>,<right>\n` | Sensor distances e.g. `SNS:80,45,75` |
| `PARK:<phase>\n` | Auto-parking phase update e.g. `PARK:2` |
| `ALERT:LOW_BATT\n` | Low battery warning |

#### Example Arduino Snippet

```cpp
#include <SoftwareSerial.h>
SoftwareSerial bt(10, 11); // RX, TX

void setup() {
  bt.begin(9600);
}

void loop() {
  // Read commands
  if (bt.available()) {
    String cmd = bt.readStringUntil('\n');
    cmd.trim();
    handleCommand(cmd);
  }

  // Send telemetry every 500ms
  static unsigned long lastTx = 0;
  if (millis() - lastTx > 500) {
    lastTx = millis();
    float pct = readBatteryPercent();   // your voltage divider → 0.0–100.0
    bt.print("B:"); bt.print(pct, 1); bt.println("%");

    bt.print("SNS:");
    bt.print(getLeftSensor()); bt.print(",");
    bt.print(getFrontSensor()); bt.print(",");
    bt.println(getRightSensor());

    if (pct < 15.0) bt.println("ALERT:LOW_BATT");
  }
}

void handleCommand(String cmd) {
  if (cmd == "MODE:M") { setMode(MANUAL); return; }
  if (cmd == "MODE:A") { setMode(AUTONOMOUS); return; }
  if (cmd == "MODE:P") { setMode(PARKING); return; }
  if (cmd == "S0")     { stopMotors(); return; }
  if (cmd == "K")      { startRecording(); return; }
  if (cmd == "E")      { stopRecordingAndLoop(); return; }
  if (cmd == "Q")      { stopPlayback(); return; }

  char dir = cmd.charAt(0);
  int spd  = cmd.substring(1).toInt(); // 1-9
  int pwm  = map(spd, 1, 9, 60, 255);

  if (dir == 'F') moveForward(pwm);
  else if (dir == 'B') moveBackward(pwm);
  else if (dir == 'L') turnLeft(pwm);
  else if (dir == 'R') turnRight(pwm);
}
```

---

## 🔧 Dependencies (pubspec.yaml)

```yaml
flutter_bluetooth_serial: ^0.4.0   # HC-05 Classic BT
permission_handler: 10.4.5         # Runtime BT/Location perms
```

---

## 📱 Android Permissions (auto-included)

- `BLUETOOTH`, `BLUETOOTH_ADMIN` (API ≤ 30)
- `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` (API 31+)
- `ACCESS_FINE_LOCATION` (required for BT discovery)

---

## 🎨 Design Notes

All colours live in `app_theme.dart` and match the HTML mockup exactly:

| Variable | Hex | Use |
|---|---|---|
| `bgPrimary` | `#0D1117` | Screen background |
| `bgCard` | `#111827` | Card backgrounds |
| `blue` | `#3B82F6` | Speed bar, active states |
| `green` | `#34D399` | Connected, battery OK |
| `red` | `#F87171` | Disconnected, low battery |
| `yellow` | `#FBBF24` | Warnings |

---

## 📝 License
MIT — free to use in your robotics project.
