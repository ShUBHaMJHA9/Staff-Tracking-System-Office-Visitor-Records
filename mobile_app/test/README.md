# Mobile App Test Suite (Python)

This folder contains Python test verification scripts for the IOD Staff Tracking System and Visitor Records.

---

## 📂 Files Included
- **`testing_strategy.md`**: Testing methodology, scope, automated tests matrix, and QA requirements.
- **`api_flows_test.py`**: Automated unittest suite verifying local client mock structures.
- **`backend_e2e_test.py`**: Live backend REST integration tests targeting local server endpoints (OTP, login, pre-register visitor).
- **`run_all_tests.py`**: Wrapper script to run all test cases with a clean output.

---

## 🏃 Run Test Suite
To run the automated tests (ensure your backend server `dotnet run` is running on `http://localhost:5124` for Suite 2 to execute live API queries):
```bash
python test/run_all_tests.py
```
