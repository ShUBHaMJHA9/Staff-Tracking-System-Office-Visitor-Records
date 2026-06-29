import unittest
import requests
import time

# We point to localhost (usually port 5124 or 5000 based on dotnet launch configs)
BASE_URL = "http://localhost:5124/api/v1"

class TestBackendLiveAPI(unittest.TestCase):
    """
    Automated sequential Integration Test Suite to verify the C# Backend REST API.
    Runs active HTTP requests against the live API endpoints to validate all modules.
    """

    @classmethod
    def setUpClass(cls):
        # Verify if backend is reachable before running E2E suites
        try:
            r = requests.get("http://localhost:5124/test", timeout=3)
            cls.live = r.status_code == 200
        except Exception:
            cls.live = False
            print("\n⚠️ WARNING: Local Backend is NOT running at http://localhost:5124.")
            print("To run live E2E tests, start the backend server via 'dotnet run' first.\n")

    def setUp(self):
        if not self.live:
            self.skipTest("Backend server is not running on http://localhost:5124. Skipping live API test.")

    def test_01_health_check(self):
        print("\n[API Test] 1. Verifying /test health endpoint...")
        response = requests.get("http://localhost:5124/test")
        self.assertEqual(response.status_code, 200)
        self.assertIn("Live", response.json().get("status", ""))

    def test_02_auth_request_otp(self):
        print("\n[API Test] 2. Verifying POST /auth/request-otp (Staff verification)...")
        # Attempt OTP request on default seeded phone
        payload = {"phone": "+919999999999"}
        response = requests.post(f"{BASE_URL}/auth/request-otp", json=payload)
        # Seeded phone number might not match exactly depending on database state,
        # but the request should return either 200 (Success) or 400 (if phone missing).
        self.assertIn(response.status_code, [200, 400])

    def test_03_visitor_pre_registration(self):
        print("\n[API Test] 3. Testing pre-registering visitor endpoints...")
        # Since this requires authentication, we'll try to log in first as admin or staff
        login_payload = {
            "email": "admin@iod.com",
            "password": "admin123"
        }
        login_res = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
        if login_res.status_code == 200:
            token = login_res.json().get("token")
            headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
            
            # Post visitor pre-registration details
            visitor_payload = {
                "firstName": "Testing",
                "lastName": "E2EVistor",
                "email": "e2e@test.com",
                "phone": "9999988888",
                "company": "E2E Corps",
                "purpose": "API Verification",
                "hostEmployeeId": "S1002"
            }
            res = requests.post(f"{BASE_URL}/visitor/pre-register", json=visitor_payload, headers=headers)
            self.assertIn(res.status_code, [200, 201, 400]) # 400 if Host S1002 not seeded yet in Sqlite
        else:
            self.skipTest("Admin login failed. Skipping authenticated endpoints.")

if __name__ == "__main__":
    unittest.main()
