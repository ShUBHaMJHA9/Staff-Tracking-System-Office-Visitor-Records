# IOD Security & Staff Tracker Mobile App

A premium, glassmorphic Flutter mobile application built for **Institute of Directors (IOD)**. It serves two distinct portals within a single codebase: a **Staff Portal** (for general employees) and a **Security Guard Portal** (for gate management and location-tracked patrol duties).

---

## 🎨 Design Philosophy
- **Modern Glassmorphic UI**: Extensive use of `BackdropFilter` and custom styling to create a premium, polished, non-AI layout.
- **Dynamic & Responsive**: Integrated dark/light mode detection, micro-animations, and custom page transitions.
- **Aesthetic Accents**: Features floating color gradient orbs (Indigo and Emerald) mirroring high-end dashboard interfaces.

---

## 🚀 Key Features

### 1. Unified Authentication
- **Secure Credentials**: Log in with standard corporate credentials.
- **OTP Verification**: Multi-factor authentication via mobile OTP flow.
- **QR Sign-in**: Quick device pairing via secure QR authentication.

### 2. Staff Portal
- **Profile Summary**: Quick stats, Designation/Department badges, and quick-action tiles.
- **Attendance Management**: In-app Clock In/Out triggered with optional biometric Face ID validation.
- **Field & Outdoor Duty Tracking**: Track coordinates in real-time when on official outdoor business.
- **Digital ID Card**: Interactive NFC-ready QR code profile card with custom filters.
- **Gate Pass Requests**: Direct early leave permission requests with dynamic status updates.
- **History log**: Clear records of all monthly check-ins and check-outs.

### 3. Security Guard Portal
- **Active Shift Status**: Live GPS patrol tracking system with background persistence.
- **Biometric Shift Punches**: Start and end shifts securely with Face ID validation.
- **Staff Attendance Gate Terminal**: Scan employee QR codes and verify physical Face ID matching using back camera validation.
- **Visitor Check-In & Gate Pass**: 
  - Business Card scanning powered by **Google ML Kit Text Recognition (OCR)**.
  - Snapshot capture for Visitor Face recognition.
  - Active visitor list with instant Check-out registry.
- **Gate Pass Validator**: Scan and validate exit passes instantly.

---

## 🛠️ Technical Specifications & Dependencies

- **SDK Requirement**: Dart `^3.10.4` | Flutter SDK
- **Core State Management**: Stateful lifecycle navigation combined with tab controllers.
- **Camera & Biometrics**: `camera`, `image_picker`, `google_mlkit_face_detection`
- **Scanning & OCR**: `mobile_scanner`, `google_mlkit_text_recognition`, `qr_flutter`
- **Background tracking**: `geolocator`, `flutter_background_service`, `flutter_local_notifications`
- **Networking**: `http` (configured for dynamic base APIs and secure JSON headers)
- **Local Storage**: `shared_preferences`

---

## 📦 Directory Cleanliness

All redundant temporary and compiler output assets have been safely expunged. Only core directories remain:
- `lib/screens/` — Hand-designed dashboards, authentication widgets, and camera modules.
- `lib/services/` — Base HTTP client mappings (`api_service.dart`) and background location services (`location_service.dart`).
- `android/` — Configuration for native Android permissions, drawable assets, and background service setup.
- `ios/` — iOS configurations.

---

## 🏃 Setup & Run Instructions

1. Ensure Flutter is installed on your local machine.
2. Run package resolution:
   ```bash
   flutter pub get
   ```
3. Run the application in debug or release mode:
   ```bash
   flutter run --release
   ```
