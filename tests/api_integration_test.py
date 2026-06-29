import unittest
import requests
import sys

# Define base URL for local backend
BASE_URL = "http://localhost:5124/api/v1"

class TestEnterpriseOmsAPI(unittest.TestCase):
    """
    Comprehensive Integration Test Suite for Enterprise OMS Backend APIs.
    Tests all endpoints (Auth, Admin, Attendance, Visitor, and Office Duty) sequentially.
    """

    token = None
    admin_headers = {}
    staff_headers = {}
    guard_headers = {}
    
    employee_id = None
    visitor_id = None
    duty_log_id = None
    gate_pass_id = None

    @classmethod
    def setUpClass(cls):
        print("\n=========================================================")
        print("    STARTING SYSTEM-WIDE ENDPOINT INTEGRATION TESTS      ")
        print("=========================================================")
        
        # Test basic server availability
        try:
            r = requests.get("http://localhost:5124/test", timeout=3)
            if r.status_code != 200:
                print("⚠️ Backend server returned unexpected status. Make sure the backend is running.")
                sys.exit(1)
        except Exception as e:
            print(f"❌ ERROR: Cannot reach backend server at http://localhost:5124: {e}")
            print("Please make sure you have started your backend API via 'dotnet run'.")
            sys.exit(1)

    def test_01_admin_login(self):
        print("\n[Auth] Testing Admin Login (POST /auth/login)...")
        payload = {
            "email": "admin@iod.com",
            "password": "admin123"
        }
        res = requests.post(f"{BASE_URL}/auth/login", json=payload)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("token", data)
        self.assertEqual(data["user"]["role"], "Admin")
        
        # Store authorization headers
        TestEnterpriseOmsAPI.token = data["token"]
        TestEnterpriseOmsAPI.admin_headers = {
            "Authorization": f"Bearer {data['token']}",
            "Content-Type": "application/json"
        }

    def test_02_create_employee(self):
        print("\n[Admin] Testing Employee Creation (POST /admin/employees)...")
        payload = {
            "firstName": "Test",
            "lastName": "Employee",
            "email": "test.emp@iod.com",
            "phone": "+918888777766",
            "department": "IT Dept",
            "designation": "QA Engineer",
            "role": "Staff"
        }
        res = requests.post(f"{BASE_URL}/admin/employees", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("id", data)
        TestEnterpriseOmsAPI.employee_id = data["id"]
        print(f"Created Employee ID: {TestEnterpriseOmsAPI.employee_id}")

    def test_03_get_employees_directory(self):
        print("\n[Admin] Testing Employee Directory Listing (GET /admin/employees)...")
        res = requests.get(f"{BASE_URL}/admin/employees", headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.json()) > 0)

    def test_04_request_otp(self):
        print("\n[Auth] Testing OTP Request (POST /auth/request-otp)...")
        payload = {"phone": "+918888777766"}
        res = requests.post(f"{BASE_URL}/auth/request-otp", json=payload)
        self.assertEqual(res.status_code, 200)

    def test_05_verify_otp(self):
        print("\n[Auth] Testing OTP Verification & Login (POST /auth/verify-otp)...")
        payload = {
            "phone": "+918888777766",
            "otp": "1234", # Configured mock OTP on backend
            "deviceId": "device_staff_qa_123"
        }
        res = requests.post(f"{BASE_URL}/auth/verify-otp", json=payload)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("token", data)
        TestEnterpriseOmsAPI.staff_headers = {
            "Authorization": f"Bearer {data['token']}",
            "Content-Type": "application/json"
        }

    def test_06_staff_attendance_checkin(self):
        print("\n[Attendance] Testing Staff Check-In (POST /attendance/check-in)...")
        payload = {
            "method": "Web",
            "ipAddress": "127.0.0.1"
        }
        res = requests.post(f"{BASE_URL}/attendance/check-in", json=payload, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)

    def test_07_staff_attendance_checkout(self):
        print("\n[Attendance] Testing Staff Check-Out (POST /attendance/check-out)...")
        res = requests.post(f"{BASE_URL}/attendance/check-out", json={}, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)

    def test_08_staff_outdoor_duty_start(self):
        print("\n[OfficeDuty] Testing Start Outdoor Duty Tracking (POST /officeduty/start)...")
        payload = {
            "destination": "IOD HQ Connaught Place",
            "reason": "UAT Review session"
        }
        res = requests.post(f"{BASE_URL}/officeduty/start", json=payload, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("dutyLogId", data)
        TestEnterpriseOmsAPI.duty_log_id = data["dutyLogId"]

    def test_09_staff_outdoor_duty_ping(self):
        print("\n[OfficeDuty] Testing Coordinate Logging (POST /officeduty/log-coordinate)...")
        payload = {
            "dutyLogId": TestEnterpriseOmsAPI.duty_log_id,
            "latitude": 28.6139,
            "longitude": 77.2090
        }
        res = requests.post(f"{BASE_URL}/officeduty/log-coordinate", json=payload, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)

    def test_10_staff_outdoor_duty_stop(self):
        print("\n[OfficeDuty] Testing Stop Outdoor Duty Tracking (POST /officeduty/stop)...")
        res = requests.post(f"{BASE_URL}/officeduty/stop", json={}, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)

    def test_11_visitor_checkin(self):
        print("\n[Visitor] Testing Visitor Check-in (POST /visitor/check-in)...")
        payload = {
            "firstName": "Guest",
            "lastName": "Visitor",
            "email": "guest@visitor.com",
            "phone": "+919988776655",
            "company": "External Partner",
            "purpose": "Business review",
            "hostEmployeeId": TestEnterpriseOmsAPI.employee_id
        }
        # Security Guard role registers visitors
        res = requests.post(f"{BASE_URL}/visitor/check-in", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("id", data)
        TestEnterpriseOmsAPI.visitor_id = data["id"]

    def test_12_visitor_active_listing(self):
        print("\n[Visitor] Testing Active Visitor Directory (GET /visitor/active)...")
        res = requests.get(f"{BASE_URL}/visitor/active", headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.json()) > 0)

    def test_13_visitor_checkout(self):
        print("\n[Visitor] Testing Visitor Checkout (POST /visitor/{id}/check-out)...")
        res = requests.post(f"{BASE_URL}/visitor/checkout-visitor", json={"id": TestEnterpriseOmsAPI.visitor_id}, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)

    def test_14_security_watchlist_create(self):
        print("\n[Admin] Testing Security Watchlist registration (POST /admin/watchlist)...")
        payload = {
            "firstName": "Banned",
            "lastName": "Individual",
            "reason": "Lobby security incident"
        }
        res = requests.post(f"{BASE_URL}/admin/watchlist", json=payload, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)

    def test_15_security_watchlist_get(self):
        print("\n[Admin] Testing Watchlist Directory (GET /admin/watchlist)...")
        res = requests.get(f"{BASE_URL}/admin/watchlist", headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.json()) > 0)

    def test_16_gate_pass_request(self):
        print("\n[GatePass] Testing Gate Pass request (POST /gatepass/request)...")
        payload = {
            "reason": "Personal medical emergency",
            "leaveTime": "18:00"
        }
        res = requests.post(f"{BASE_URL}/gatepass/request", json=payload, headers=self.staff_headers)
        self.assertEqual(res.status_code, 200)
        
        data = res.json()
        self.assertIn("passCode", data)
        TestEnterpriseOmsAPI.gate_pass_id = data["id"]

    def test_17_gate_pass_admin_approvals(self):
        print("\n[GatePass] Testing Gate Pass Approval by Admin (POST /gatepass/approve)...")
        res = requests.post(f"{BASE_URL}/gatepass/approve/{TestEnterpriseOmsAPI.gate_pass_id}", json={}, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)

    def test_18_gate_pass_redemption_scan(self):
        print("\n[GatePass] Testing Security Gate Pass redemption scan (POST /gatepass/scan)...")
        res = requests.post(f"{BASE_URL}/gatepass/scan", json={"passCode": f"GP-{TestEnterpriseOmsAPI.gate_pass_id}"}, headers=self.admin_headers)
        self.assertEqual(res.status_code, 200)

if __name__ == "__main__":
    unittest.main()
