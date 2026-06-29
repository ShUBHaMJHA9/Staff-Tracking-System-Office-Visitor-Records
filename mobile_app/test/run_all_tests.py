import subprocess
import sys
import os

def run_tests():
    print("=========================================================")
    print("   IOD STAFF TRACKING & VISITOR RECORDS AUTOMATED TESTS  ")
    print("=========================================================")
    
    test_file_mock = os.path.join(os.path.dirname(__file__), "api_flows_test.py")
    test_file_e2e = os.path.join(os.path.dirname(__file__), "backend_e2e_test.py")
    
    print("\n[Suite 1] Running Mock and Serialization Unit Tests...")
    result_mock = subprocess.run([sys.executable, test_file_mock], capture_output=False)
    
    print("\n[Suite 2] Running Live Backend E2E API Verification Tests...")
    result_e2e = subprocess.run([sys.executable, test_file_e2e], capture_output=False)
    
    if result_mock.returncode == 0 and result_e2e.returncode == 0:
        print("\n🎉 All test suites (Mock & E2E Live API) PASSED successfully!")
        sys.exit(0)
    else:
        print("\n❌ One or more tests failed. Check trace above.")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
