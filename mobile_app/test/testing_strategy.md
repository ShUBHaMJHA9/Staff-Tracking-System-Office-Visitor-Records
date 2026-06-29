# Software Development Life Cycle (SDLC) — Testing Strategy Document

**Project**: IOD Enterprise Operations Management System (EMS)  
**Modules**: Staff Tracking System | Office Visitor Records  
**Organization**: Institute of Directors (IOD)  
**Prepared by**: Shubham Jha  
**Supervised by**: Mr. Ravi Shankar Swami (HoD – Web & IT), IOD  
**Document Version**: 1.0  
**Date**: June 2026  

---

## 1. Introduction

This document defines the formal Testing Strategy for the **Staff Tracking System** and **Office Visitor Records** modules of the IOD Enterprise Operations Management System. It outlines the testing methodology, types, environments, tools, test case design, defect tracking, and acceptance criteria aligned to each phase of the Software Development Life Cycle (SDLC).

The system consists of two primary components:
- **Backend REST API** — ASP.NET Core 9, SQLite/PostgreSQL, JWT Authentication.
- **Mobile Application** — Flutter (Android/iOS) for Staff and Security Guard portals.

---

## 2. Objectives

| Objective | Description |
|---|---|
| **Correctness** | Verify all API endpoints return expected HTTP status codes, payloads, and business logic. |
| **Security** | Validate JWT authentication, biometric matching, OTP verification, and single-device enforcement. |
| **Reliability** | Ensure background GPS tracking and foreground notification services are resilient across device states. |
| **Usability** | Confirm UI flows are intuitive and visually correct across light/dark modes. |
| **Performance** | Validate response times are acceptable under concurrent load. |
| **Compliance** | Ensure attendance timestamps and visitor records are accurate and tamper-resistant. |

---

## 3. Scope of Testing

### 3.1 In Scope

**Staff Tracking System**
- Multi-factor login flows (Email/Password, OTP, QR Token)
- Face ID biometric verification screen
- Attendance clock-in and clock-out with GPS timestamp
- Outdoor Office Duty GPS tracking (background service)
- Gate Pass request and status tracking
- Staff digital ID card with QR generation
- Admin attendance report and employee management portal

**Office Visitor Records**
- Visitor pre-registration by Staff
- Business card OCR scanning by Security Guard
- Visitor Face photo capture and match verification
- Active visitor list with real-time checkout
- Security watchlist threat detection and alert dispatch
- Gate Pass scanning and redemption by Guard
- Admin visitor master log, filtering, and reporting

### 3.2 Out of Scope
- Native iOS build pipeline and App Store distribution.
- Third-party SMS OTP gateway integration (mocked with static OTP `1234`).
- Web Admin portal end-to-end browser automation.

---

## 4. SDLC Testing Phases

The testing activities are aligned with each SDLC phase to ensure quality is built in, not bolted on.

```
┌──────────────────────────────────────────────────────────────────────┐
│  SDLC PHASE              TESTING ACTIVITY                            │
├──────────────────────────────────────────────────────────────────────┤
│  1. Requirement Analysis  → Review & test requirements (RT)          │
│  2. System Design         → Architecture review, API contract tests  │
│  3. Implementation        → Unit Tests, Static Code Analysis         │
│  4. Integration           → Component & API Integration Tests        │
│  5. Testing               → System Testing, Security, Performance    │
│  6. Deployment            → Smoke Tests, Regression Suite            │
│  7. Maintenance           → Regression on hotfixes, patch validation │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 5. Test Types & Methodology

### 5.1 Unit Testing
**Target**: Individual controller methods, service functions, and model validations.  
**Tool**: Python `unittest`, xUnit (.NET).  
**Approach**: Mock database contexts and HTTP dependencies. Verify pure business logic.

| Test ID | Module | Test Case | Expected Result |
|---|---|---|---|
| UT-AUTH-01 | Auth | OTP generation sets `CurrentOtp` field | `user.CurrentOtp != null` |
| UT-AUTH-02 | Auth | Expired OTP is rejected | `401 Unauthorized` |
| UT-AUTH-03 | Auth | Login with wrong password returns 401 | `401 Unauthorized` |
| UT-ATT-01 | Attendance | Double check-in attempt is blocked | `400 "already clocked in"` |
| UT-ATT-02 | Attendance | Checkout without active session | `400 "no active session"` |
| UT-VIS-01 | Visitor | Blacklisted visitor triggers alert | `isWatchlist == true` |
| UT-VIS-02 | Visitor | Pre-registered visitor lookup by card ID | `200` with visitor details |
| UT-GP-01 | GatePass | Non-approved gate pass rejected on scan | `403 or 400` response |

---

### 5.2 Integration Testing
**Target**: Component interactions — Controller → Service → Database and Mobile App → REST API.  
**Tool**: Python `requests` library against live local server (`http://localhost:5124`).  
**Approach**: Sequential API call chains that simulate real user sessions.

| Test ID | Flow | Steps | Expected Result |
|---|---|---|---|
| IT-01 | Staff Login → Attendance | 1. `POST /auth/login` → 2. `POST /attendance/check-in` | JWT issued → Clock-in recorded |
| IT-02 | OTP Flow | 1. `POST /auth/request-otp` → 2. `POST /auth/verify-otp` | OTP sent → JWT issued |
| IT-03 | Guard Shift | 1. Login → 2. `POST /attendance/shift-start` → 3. GPS logs | Shift active, coordinates saved |
| IT-04 | Visitor Flow | 1. Login as Staff → 2. `POST /visitor/pre-register` → 3. Guard scans QR | Visitor pass generated → check-in confirmed |
| IT-05 | Gate Pass | 1. Staff requests pass → 2. Admin approves → 3. Guard scans | Pass redeemed successfully |
| IT-06 | Watchlist Alert | 1. Register blacklisted visitor name → 2. Guard check-in | Security alert dispatched |

---

### 5.3 System Testing
**Target**: Complete end-to-end system behavior matching functional requirements.  
**Environment**: Staging with production data shape (seeded SQLite).  

**E2E Scenario 1 — Staff Full Day Cycle:**
```
Login (OTP) → Face ID Verify → Clock In
  → Start Office Duty (GPS tracking begins)
  → Stop Office Duty
  → Request Gate Pass (early leave)
  → Admin Approves Gate Pass
  → Clock Out
  → View Attendance History
```

**E2E Scenario 2 — Visitor Entry Cycle:**
```
Guard Login (Face ID) → Start Shift
  → Visitor Arrives → Guard scans Business Card (OCR)
  → Face Photo Captured
  → System checks Watchlist → CLEAR
  → Visitor Check-In Confirmed → Pass Issued
  → Visitor Exits → Guard Checks Out Visitor
  → Admin reviews Visitor Master Log
```

**E2E Scenario 3 — Security Threat Detection:**
```
Visitor on Watchlist attempts entry
  → Guard scans ID Card
  → Backend matches Watchlist → THREAT DETECTED
  → Red alert modal displayed to Guard
  → Audit Log records event with severity "critical"
  → Admin receives notification
```

---

### 5.4 Security Testing

| Test ID | Security Check | Method | Pass Criteria |
|---|---|---|---|
| SEC-01 | JWT token expiry enforcement | Send expired token | `401 Unauthorized` |
| SEC-02 | Single device enforcement | Login from 2nd device | Old token invalidated |
| SEC-03 | Unauthorized route access | Call `GET /attendance/history` without token | `401 Unauthorized` |
| SEC-04 | Admin-only route protection | Call admin endpoints with Staff JWT | `403 Forbidden` |
| SEC-05 | Invalid biometric rejection | Send mismatched face photo | Face match returns `false` |
| SEC-06 | SQL injection attempt | Craft email with SQL payload | Input sanitized, `400 BadRequest` |

---

### 5.5 Performance Testing
**Target**: API response times under concurrent load.  
**Tool**: Python `threading` module with concurrent HTTP requests.

| Endpoint | Concurrent Users | Acceptable Response Time |
|---|---|---|
| `POST /auth/login` | 20 | < 500ms |
| `GET /visitor/active` | 10 | < 200ms |
| `POST /attendance/check-in` | 30 | < 400ms |
| `POST /officeduty/log-coordinate` | 50 | < 300ms |
| `GET /admin/attendance-report` | 5 | < 1000ms |

---

### 5.6 Regression Testing
**When**: After every new feature merge or hotfix deployment.  
**Scope**: All `IT-xx` integration tests + critical `E2E Scenario 1 & 2`.  
**Tool**: `python test/run_all_tests.py` executed in CI pipeline.

---

### 5.7 User Acceptance Testing (UAT)
**Participants**: Mr. Ravi Shankar Swami (HoD), selected IOD staff, and security personnel.  
**Environment**: Pre-production staging server with anonymized real-data shape.  
**UAT Scenarios**:
1. Staff clocks in and confirms the time displayed matches their device clock.
2. Security guard scans a test visitor card and confirms correct details appear.
3. Admin approves a gate pass and confirms the guard scanner reflects the status change.
4. Admin reviews visitor records filtered by date and confirms data integrity.

**Acceptance Criteria**: All P1 (Critical) defects resolved. UAT sign-off from HoD.

---

## 6. Test Environment Setup

```
┌─────────────────────────────────────────────────────────────────┐
│  ENVIRONMENT      DETAILS                                        │
├─────────────────────────────────────────────────────────────────┤
│  Development      localhost:5124 (dotnet run)                    │
│                   Flutter debug build on physical Android device │
│  Staging          Cloudflare Tunnel HTTPS URL                    │
│                   Seeded SQLite database with mock user data     │
│  Production       Deployment target (post-UAT sign-off)         │
└─────────────────────────────────────────────────────────────────┘
```

**Dependencies:**
- Python `>= 3.8` (for automated test scripts)
- `requests` library: `pip install requests`
- `dotnet SDK 9.0` (backend runtime)
- `Flutter SDK >= 3.10` (mobile app build)
- Android device/emulator for mobile E2E scenarios

---

## 7. Defect Management

### 7.1 Defect Priority Levels

| Priority | Description | Resolution SLA |
|---|---|---|
| **P1 – Critical** | System crash, security bypass, data loss | Immediate (same day) |
| **P2 – High** | Core feature fails (login, check-in, visitor entry) | 24 hours |
| **P3 – Medium** | Non-critical feature behaves unexpectedly | 3 days |
| **P4 – Low** | UI misalignment, minor text issues | Next sprint |

### 7.2 Defect Lifecycle
```
New → Assigned → In Progress → Fixed → Verified → Closed
                                      ↓
                                  Reopened (if regression found)
```

---

## 8. Test Metrics & KPIs

| Metric | Target |
|---|---|
| Test Case Pass Rate | ≥ 95% before UAT |
| Critical Defect Count (P1) at UAT entry | 0 |
| API Average Response Time | < 400ms |
| Biometric False Accept Rate | < 0.1% |
| Attendance Timestamp Accuracy | ± 1 second of server time |
| Code Coverage (Unit Tests) | ≥ 70% |

---

## 9. Test Deliverables

| Deliverable | Description |
|---|---|
| `testing_strategy.md` | This document |
| `api_flows_test.py` | Automated Python unit & mock tests |
| `backend_e2e_test.py` | Live REST API integration tests |
| `run_all_tests.py` | Single-command test runner |
| `test/README.md` | Setup and execution guide |
| UAT Sign-off Sheet | Physical/digital sign-off from HoD after UAT |

---

## 10. Roles & Responsibilities

| Role | Responsibility |
|---|---|
| **Developer (Shubham Jha)** | Write unit tests, integration tests, fix defects |
| **HoD – Mr. Ravi Shankar Swami** | Review test strategy, conduct UAT, final sign-off |
| **Security Guard (Tester)** | Execute UAT scenarios for Guard portal |
| **Staff Member (Tester)** | Execute UAT scenarios for Staff portal |

---

## 11. Entry & Exit Criteria

### Entry Criteria (before testing begins)
- [ ] All planned features are implemented and peer-reviewed.
- [ ] Backend server deploys successfully with zero startup errors.
- [ ] Mobile app installs on Android device without crashes.
- [ ] Test database is seeded with minimum required records.

### Exit Criteria (before production release)
- [ ] All P1 and P2 defects are resolved and regression-tested.
- [ ] Automated test suite passes with 100% on critical paths.
- [ ] UAT scenarios signed off by HoD.
- [ ] Performance benchmarks meet defined KPIs.
- [ ] Security test checklist completed with no open vulnerabilities.

---

*Document prepared as part of the SDLC process documentation for internship at the Institute of Directors (IOD), New Delhi.*
