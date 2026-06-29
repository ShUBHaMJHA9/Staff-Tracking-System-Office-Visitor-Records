# Enterprise OMS - API Test Report

This document outlines all verified endpoints within the Enterprise OMS `.NET 9` backend, detailing the expected request payloads, authentication requirements, and security enforcements.

## Authentication & Security Rules
- **JWT Protection**: Most endpoints require a valid JWT passed via the `Authorization: Bearer <token>` header.
- **Single Device Policy**: The system strictly enforces one device per employee. 
  - When an employee logs in, the server generates an `ActiveTokenId` and stores it. 
  - If they log in from another device, the old token becomes invalid and attempting to use it will return `401 Unauthorized: Session expired. Logged in from another device.`

---

## 1. Auth Module (`/api/v1/auth`)

### `POST /api/v1/auth/login`
- **Protected:** `False` (Public)
- **Description:** Authenticates user and issues a 365-day persistent JWT. Revokes tokens on other devices.
- **Payload:**
```json
{
  "email": "admin@iod.com",
  "password": "admin123"
}
```
- **Expected Status:** `200 OK`
- **Response Shape:** `{ "token": "ey..." }`

---

## 2. Admin Module (`/api/v1/admin`)

### `GET /api/v1/admin/employees`
- **Protected:** `True` (Requires JWT)
- **Description:** Fetches full employee directory.
- **Payload:** `None`
- **Expected Status:** `200 OK`

### `POST /api/v1/admin/employees`
- **Protected:** `True`
- **Description:** Creates a new employee.
- **Payload:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@iod.com",
  "phone": "+91-9988001122",
  "department": "Engineering",
  "designation": "Developer",
  "role": "Staff"
}
```

### `GET /api/v1/admin/watchlist`
- **Protected:** `True`
- **Description:** Returns all individuals flagged in the security watchlist.
- **Payload:** `None`

### `POST /api/v1/admin/watchlist`
- **Protected:** `True`
- **Description:** Flags a new individual for lobby security screening.
- **Payload:**
```json
{
  "firstName": "Suspect",
  "lastName": "One",
  "reason": "Security violation"
}
```

---

## 3. Attendance Module (`/api/v1/attendance`)

### `GET /api/v1/attendance/status`
- **Protected:** `True`
- **Description:** Gets current active check-in status for logged-in user.
- **Payload:** `None`

### `POST /api/v1/attendance/check-in`
- **Protected:** `True`
- **Description:** Registers a physical check-in for the employee.
- **Payload:**
```json
{
  "method": "Web",
  "ipAddress": "192.168.1.5"
}
```

### `POST /api/v1/attendance/check-out`
- **Protected:** `True`
- **Description:** Closes the current active attendance log.
- **Payload:** `None`

---

## 4. Visitor Management (`/api/v1/visitor`)

### `GET /api/v1/visitor/active`
- **Protected:** `True`
- **Description:** Gets all currently checked-in visitors across the campus.

### `POST /api/v1/visitor/check-in`
- **Protected:** `True`
- **Description:** Registers a new guest and assigns a host employee.
- **Payload:**
```json
{
  "firstName": "Raj",
  "lastName": "Mehta",
  "email": "raj@partner.com",
  "phone": "+91-8888777700",
  "company": "Partner LLC",
  "hostEmployeeId": "00000000-0000-0000-0000-000000000001",
  "purpose": "Business Meeting"
}
```

### `POST /api/v1/visitor/{id}/check-out`
- **Protected:** `True`
- **Description:** Checks out an active visitor.
- **Payload:** `None`

---

## 5. Field Duty & GPS Tracking (`/api/v1/duty`)

### `GET /api/v1/duty/active`
- **Protected:** `True`
- **Description:** Fetches all ongoing field duties and their real-time decrypted GPS coordinate histories.

### `POST /api/v1/duty/start`
- **Protected:** `True`
- **Description:** Initiates out-of-office GPS tracking.
- **Payload:**
```json
{
  "destination": "Client HQ, Nehru Place",
  "reason": "Hardware Installation"
}
```

### `POST /api/v1/duty/ping`
- **Protected:** `True`
- **Description:** Continuous endpoint for mobile app to send AES encrypted GPS coordinates.
- **Payload:**
```json
{
  "latitude": 28.5494,
  "longitude": 77.2519
}
```
*(Note: These doubles are transparently encrypted via `EncryptionService.cs` before SQLite database persistence).*
