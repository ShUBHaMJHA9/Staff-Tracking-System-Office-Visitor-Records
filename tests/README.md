# Enterprise OMS API Testing Environment

This directory houses the comprehensive integration testing suite for verifying the REST API endpoints of the `.NET 9` backend.

---

## 📂 Test Components

- **`api_integration_test.py`**: Sequential integration test suite containing 18 discrete test cases testing Auth (Password/OTP), Employee Creation, Attendance (Check-in/Check-out), Field Duty (GPS logging), Visitor Management, Watchlists, and early exit Gate Passes.
- **`API_TEST_REPORT.md`**: Specification document mapping API payload shapes, parameters, responses, and authorization definitions.
- **`endpoints.http`**: REST Client configuration file for local manual testing.

---

## 🏃 Setup & Execution

### 1. Requirements
Ensure your Python testing environment is ready:
```bash
pip install requests
```

### 2. Execute Tests
Start your backend server first via:
```bash
cd backend-api
dotnet run
```

Then, run the automated integration test script in another terminal:
```bash
cd tests
python api_integration_test.py
```
