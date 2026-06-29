# Continuous Integration & Continuous Deployment (CI/CD) Strategy

This document establishes the official build, test, and release deployment strategy for the IOD Enterprise Operations Management System (EMS).

---

## 🏗️ 1. CI/CD Architecture Overview

The system runs on a automated pipeline that spans the Mobile Client, C# Backend API, and Python AI Service.

```
[ Developer Commit ] ──> [ GitHub Action runner ]
                              │
       ┌──────────────────────┼──────────────────────┐
       ▼                      ▼                      ▼
  [ Mobile Build ]     [ Backend API Build ]    [ AI Service ]
  - Flutter analyze    - Dotnet build           - Pip install lint
  - Test run (mock)    - xUnit tests            - Verify imports
       │                      │                      │
       └──────────────────────┼──────────────────────┘
                              ▼
                [ Staging Environment Deploy ]
                - Cloudflare Tunnel routing
                - SQLite migrations execution
```

---

## 🛠️ 2. Build and Test Automation (CI)

### 2.1 Backend CI Workflow
On every push/pull request:
1. Restore dependencies:
   ```bash
   dotnet restore
   ```
2. Build project on Release configuration:
   ```bash
   dotnet build --configuration Release --no-restore
   ```
3. Run automated tests:
   ```bash
   dotnet test --no-build --verbosity normal
   ```

### 2.2 Mobile Client CI Workflow
On every push to feature branches:
1. Get packages:
   ```bash
   flutter pub get
   ```
2. Static Analysis:
   ```bash
   flutter analyze
   ```
3. Run Local Unit/Widget Tests:
   ```bash
   flutter test
   ```

---

## 🚀 3. Deployment Pipeline (CD)

### 3.1 Backend & Database Deployment
- **Staging**: Pushed to staging server running behind **Cloudflare Tunnel (Argo)** for secure, public HTTPS mapping without open firewall ports.
- **Database Migrations**: Entity Framework Core automatically runs database migrations on startup using `context.Database.Migrate();` inside `Program.cs`.
- **Concurrency Setup**: The server initiates SQLite with `PRAGMA journal_mode=WAL;` to allow simultaneous reads/writes.

### 3.2 Python AI Service Deployment
- Deployed on a GPU-enabled micro-instance (running FastAPI + DeepFace model weights).
- Managed via `systemd` services or Docker containerization:
  ```bash
  uvicorn main:app --host 0.0.0.0 --port 5125 --workers 4
  ```

### 3.3 Mobile App Release
- Android APK compiled using Release variant:
  ```bash
  flutter build apk --release
  ```
- Resulting package located at `build/app/outputs/flutter-apk/app-release.apk`.
