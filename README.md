# IOD Enterprise Operations Management System (EMS)

A comprehensive, production-grade operations tracking platform built for the **Institute of Directors (IOD)**. The system serves two primary modules to digitize and monitor corporate logistics:

1. **Staff Tracking System** (MFA Login, Biometric Face ID, Outdoor Duty GPS tracking, Early Leave Gate Passes)
2. **Office Visitor Records** (Pre-registration, Front desk OCR ID Scanning, Lobby Threat Watchlists, Security clearance validation)

---

## 🏗️ System Architecture

The platform follows a modern, distributed architecture:

```
                  ┌──────────────────────────────┐
                  │      React Admin Portal      │
                  │   (Vite Dashboard Frontend)  │
                  └──────────────┬───────────────┘
                                 │ HTTP / JSON
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ASP.NET Core 9 Backend API                   │
│         - Handles Authorization, JWT Single-Device Tokens       │
│         - EF Core with SQLite (WAL Logging)                     │
│         - AES-256 Encryption Service (for secure GPS storage)   │
└──────────────┬──────────────────────────────────┬───────────────┘
               │                                  │
               │ HTTP / multipart                 │ HTTP / JSON
               ▼                                  ▼
┌──────────────────────────────┐   ┌──────────────────────────────┐
│      Python AI Service       │   │     Flutter Mobile App       │
│  - FastAPI Web Frame         │   │  - Shared Staff/Guard modes  │
│  - DeepFace Cosine Matcher   │   │  - Background GPS Service    │
│  - VGG-Face Neural Model     │   │  - QR & Camera OCR modules   │
└──────────────────────────────┘   └──────────────────────────────┘
```

---

## 📂 Repository Structure

- **[`/backend-api`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/backend-api)**: Main REST controller layer built with `.NET 9`, implementing custom middleware for single-session JWT checking.
- **[`/mobile_app`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/mobile_app)**: Single-codebase cross-platform Flutter application featuring custom animated glassmorphism UIs, background location pings, and native scanner overlays.
- **[`/admin-portal`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/admin-portal)**: React administration UI providing live GPS tracking maps, visitor manifests, employee rosters, and whitelist audit control views.
- **[`/python-ai-service`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/python-ai-service)**: FastAPI neural matcher processing cosine-similarity calculations for security gates.
- **[`/database`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/database)**: Schema designs, WAL concurrency settings, and pre-seeded SQLite configurations.
- **[`/tests`](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/tests)**: 18-step sequential integration testing script validating API calls and backend logic.

---

## 🛡️ Risk Assessment & Security Countermeasures

To satisfy SDLC compliance, the following risk matrix details identified vulnerabilities and their active mitigations in code:

| Risk Domain | Potential Vulnerability | System Mitigations & Countermeasures |
|---|---|---|
| **Identity Hijack** | Device duplication or token theft. | **Single-Device Policy**: Token ids are rotated on login; older sessions automatically return `401 Unauthorized`. |
| **Location Leak** | Eavesdropping on employee outdoor paths. | **AES-256 Encryption**: Location doubles are natively encrypted via `EncryptionService.cs` before database persistence. |
| **Lobby Intrusion** | Watchlisted targets entering premises. | **Real-time Threat Matching**: Check-in triggers instant database watchlist lookup with immediate red alerts shown to security guards. |
| **Session Session Spoof** | Brute forcing OTP tokens. | **Expiry SLA & Lockouts**: Mock OTP verification requires a matching temporary hash and is validated with UTC expiration timestamps. |
| **System Outage** | Database locks during high-frequency GPS coordinate pings. | **WAL Logging Mode**: SQLite database operates under Write-Ahead Logging (`PRAGMA journal_mode=WAL;`), allowing concurrent reads and writes. |

---

## 🏃 Run & Development Setup

Review instructions inside individual subdirectories for execution details:
1. **API Server**: [backend-api/README.md](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/backend-api/README.md)
2. **Mobile App**: [mobile_app/README.md](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/mobile_app/README.md)
3. **AI Matching**: [python-ai-service/README.md](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/python-ai-service/README.md)
4. **Integration Tests**: [tests/README.md](file:///c:/Users/jha95/OneDrive/Documents/PROJECT/enterprise-oms/tests/README.md)
