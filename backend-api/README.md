# Enterprise OMS - Backend API Documentation

This is the production-ready backend service for the Enterprise Office Management System (OMS). Built on .NET Core, it uses Entity Framework Core for data persistence and provides a RESTful architecture for the Admin Portal and Mobile Apps.

---

## 🚀 Getting Started

To run the application locally:
1. Restore dependencies: `dotnet restore`
2. Apply database migrations: `dotnet ef database update`
3. Run the application: `dotnet run`

---

## 📖 API Documentation (Detailed Endpoints)

All endpoints accept and return `application/json` unless specified otherwise.
Most endpoints require a Bearer token in the `Authorization` header.

---

### 1. Authentication API (`/api/auth`)
Handles user authentication and onboarding.

#### `POST /api/auth/login`
Standard Email & Password login.
- **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "guid-uuid",
      "firstName": "John",
      "lastName": "Doe",
      "role": "Staff"
    }
  }
  ```

#### `POST /api/auth/request-otp`
Requests a 4-digit OTP to the registered phone number.
- **Request Body**:
  ```json
  {
    "phone": "+919876543210"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "OTP sent successfully"
  }
  ```

#### `POST /api/auth/verify-otp`
Verifies an OTP and logs the user in.
- **Request Body**:
  ```json
  {
    "phone": "+919876543210",
    "otp": "1234",
    "deviceId": "device-uuid-1234"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOi...",
    "message": "OTP verified successfully",
    "role": "SecurityGuard"
  }
  ```

#### `POST /api/auth/qr-login`
Authenticates using a pre-generated QR code token.
- **Request Body**:
  ```json
  {
    "token": "qr-token-string",
    "deviceId": "device-uuid-1234"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOi...",
    "user": {
      "id": "guid-uuid",
      "role": "Staff"
    }
  }
  ```

#### `POST /api/auth/verify-face`
Authenticates via facial recognition.
- **Request Body**:
  ```json
  {
    "userId": "guid-uuid",
    "image": "base64-encoded-image-data..."
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "token": "eyJhbGciOi...",
    "message": "Face verified successfully"
  }
  ```

#### `POST /api/auth/activate`
Activates a new device.
- **Request Body**:
  ```json
  {
    "activationCode": "ABCDEF1234"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Device activated successfully"
  }
  ```

#### `GET /api/auth/me`
Retrieves current session info.
- **Request Body**: None (Requires Auth Header)
- **Response (200 OK)**:
  ```json
  {
    "id": "guid-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "Staff"
  }
  ```

---

### 2. Visitor Management API (`/api/visitor`)
Used heavily by the Security Guard and Staff roles to manage guest access.

#### `POST /api/visitor/pre-register`
Staff pre-registers a visitor.
- **Request Body**:
  ```json
  {
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane@vendor.com",
    "phone": "+919998887776",
    "company": "Vendor Inc",
    "purpose": "Consultation",
    "designation": "Manager"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Visitor pre-registered successfully",
    "visitorId": "guid-uuid"
  }
  ```

#### `GET /api/visitor/lookup/{cardId}`
Security guard scans physical ID card.
- **Response (200 OK)**:
  ```json
  {
    "id": "guid-uuid",
    "firstName": "Jane",
    "lastName": "Smith",
    "hostName": "John Doe",
    "status": "Checked In"
  }
  ```

#### `GET /api/visitor/employees`
Lists employees available to host visitors.
- **Response (200 OK)**:
  ```json
  [
    { "id": "guid-1", "name": "John Doe", "department": "IT" },
    { "id": "guid-2", "name": "Anita Sharma", "department": "HR" }
  ]
  ```

#### `POST /api/visitor/check-in`
- **Request Body**:
  ```json
  {
    "visitorId": "guid-uuid",
    "visitorCardId": "CARD-001"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Check-in successful",
    "status": "Checked In"
  }
  ```

#### `POST /api/visitor/check-out/{id}`
- **Response (200 OK)**:
  ```json
  {
    "message": "Check-out successful",
    "status": "Checked Out"
  }
  ```

#### `GET /api/visitor/active`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid",
      "firstName": "Jane",
      "lastName": "Smith",
      "company": "Vendor Inc",
      "status": "Checked In",
      "checkInTime": "2026-06-29T10:00:00Z"
    }
  ]
  ```

#### `GET /api/visitor/all`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid",
      "firstName": "Jane",
      "lastName": "Smith",
      "status": "Checked Out",
      "checkInTime": "2026-06-29T10:00:00Z",
      "checkOutTime": "2026-06-29T12:00:00Z"
    }
  ]
  ```

---

### 3. Office Duty & Tracking API (`/api/officeduty`)
Handles GPS tracking when employees are on official duty outside the office.

#### `POST /api/officeduty/start`
- **Request Body**:
  ```json
  {
    "destination": "Client Site B",
    "reason": "Networking Setup"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "dutyLogId": "guid-uuid",
    "message": "Duty started successfully"
  }
  ```

#### `POST /api/officeduty/stop`
- **Request Body**:
  ```json
  {
    "dutyLogId": "guid-uuid"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Duty stopped successfully"
  }
  ```

#### `POST /api/officeduty/location` / `POST /api/officeduty/log-coordinate`
- **Request Body**:
  ```json
  {
    "dutyLogId": "guid-uuid",
    "latitude": 28.5355,
    "longitude": 77.3910
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Coordinate logged"
  }
  ```

#### `GET /api/officeduty/active`
- **Response (200 OK)**:
  ```json
  {
    "id": "guid-uuid",
    "destination": "Client Site B",
    "status": "Active",
    "startTime": "2026-06-29T09:00:00Z",
    "coordinates": [
      { "latitude": 28.5355, "longitude": 77.3910, "timestamp": "2026-06-29T09:05:00Z" }
    ]
  }
  ```

---

### 4. Gate Pass API (`/api/gatepass`)
Allows staff to request to leave early.

#### `POST /api/gatepass/request`
- **Request Body**:
  ```json
  {
    "reason": "Doctor appointment",
    "leaveTime": "14:30"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Gate pass requested successfully"
  }
  ```

#### `GET /api/gatepass/my-passes`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "reason": "Doctor appointment",
      "leaveTime": "14:30",
      "approvalStatus": "Pending",
      "passCode": "GP-XYZ123"
    }
  ]
  ```

#### `GET /api/gatepass/pending`
Admin view for pending passes.
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "userId": "staff-guid",
      "reason": "Personal work",
      "approvalStatus": "Pending"
    }
  ]
  ```

#### `POST /api/gatepass/approve/{id}`
Admin approves pass.
- **Request Body**:
  ```json
  {
    "status": "Approved"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Gate pass approved"
  }
  ```

#### `POST /api/gatepass/scan/{passCode}`
Guard scans code.
- **Response (200 OK)**:
  ```json
  {
    "message": "Pass valid",
    "userId": "staff-guid"
  }
  ```

---

### 5. Attendance API (`/api/attendance`)

#### `POST /api/attendance/check-in`
- **Request Body**:
  ```json
  {
    "method": "Web",
    "ipAddress": "192.168.1.1"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Checked in successfully"
  }
  ```

#### `POST /api/attendance/check-out`
- **Request Body**: Empty body `{}` or none.
- **Response (200 OK)**:
  ```json
  {
    "message": "Checked out successfully"
  }
  ```

#### `GET /api/attendance/history`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "checkIn": "2026-06-29T09:00:00Z",
      "checkOut": "2026-06-29T17:00:00Z",
      "checkInMethod": "QR"
    }
  ]
  ```

#### `GET /api/attendance/active-shift`
- **Response (200 OK)**:
  ```json
  {
    "id": "guid-uuid",
    "checkIn": "2026-06-29T09:00:00Z",
    "checkInMethod": "Face"
  }
  ```

#### `GET /api/attendance/employee/{id}`
Admin retrieves history.
- **Response (200 OK)**: Same as `/api/attendance/history` above.

---

### 6. Admin Control API (`/api/admin`)
Requires `Admin` role.

#### `GET /api/admin/employees`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "firstName": "John",
      "lastName": "Doe",
      "email": "john@example.com",
      "department": "IT",
      "designation": "Manager",
      "role": "Staff",
      "isActive": true
    }
  ]
  ```

#### `POST /api/admin/employees`
- **Request Body**:
  ```json
  {
    "firstName": "Alice",
    "lastName": "Smith",
    "email": "alice@example.com",
    "department": "HR",
    "designation": "Recruiter",
    "role": "Staff"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Employee created successfully",
    "employeeId": "guid-uuid"
  }
  ```

#### `POST /api/admin/employees/update/{id}`
- **Request Body**:
  ```json
  {
    "department": "Finance",
    "designation": "Lead"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Employee updated successfully"
  }
  ```

#### `POST /api/admin/employees/toggle/{id}`
- **Response (200 OK)**:
  ```json
  {
    "message": "Employee status toggled to inactive"
  }
  ```

#### `GET /api/admin/employees/{id}/get-qr`
- **Response (200 OK)**:
  ```json
  {
    "qrToken": "qr-token-string"
  }
  ```

#### `POST /api/admin/employees/{id}/generate-qr`
- **Response (200 OK)**:
  ```json
  {
    "message": "QR generated",
    "qrToken": "new-qr-token-string"
  }
  ```

#### `POST /api/admin/employees/register-face/{id}`
- **Request Body**:
  ```json
  {
    "photoBase64": "data:image/jpeg;base64,/9j/4AAQSkZJ..."
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Face profile registered"
  }
  ```

#### `GET /api/admin/watchlist`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "firstName": "Banned",
      "lastName": "Person",
      "phone": "+910000000000",
      "reason": "Trespassing",
      "flaggedAt": "2026-06-01T00:00:00Z"
    }
  ]
  ```

#### `POST /api/admin/watchlist`
- **Request Body**:
  ```json
  {
    "firstName": "Banned",
    "lastName": "Person",
    "phone": "+910000000000",
    "email": "banned@example.com",
    "reason": "Trespassing"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "message": "Added to watchlist"
  }
  ```

#### `DELETE /api/admin/watchlist/{id}`
- **Response (200 OK)**:
  ```json
  {
    "message": "Removed from watchlist"
  }
  ```

#### `GET /api/admin/logs`
- **Response (200 OK)**:
  ```json
  [
    {
      "id": "guid-uuid",
      "timestamp": "2026-06-29T10:00:00Z",
      "user": "System",
      "action": "Visitor Check-in",
      "details": "Visitor checked in successfully",
      "severity": "info"
    }
  ]
  ```

#### `GET /api/admin/attendance-report`
- **Response (200 OK)**:
  ```json
  {
    "totalCheckIns": 150,
    "totalAbsences": 12,
    "averageHours": 8.5
  }
  ```

#### `GET /api/admin/visitor-report`
- **Response (200 OK)**:
  ```json
  {
    "totalVisitors": 45,
    "activeVisitors": 5
  }
  ```

#### `GET /api/admin/shift-report`
- **Response (200 OK)**:
  ```json
  {
    "discrepancies": 2,
    "details": [...]
  }
  ```
