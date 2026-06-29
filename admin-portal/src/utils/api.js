// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\admin-portal\src\utils\api.js

const API_BASE = "http://localhost:3000/api/v1";

const getHeaders = () => {
  const token = localStorage.getItem("iod_jwt_token");
  return {
    "Content-Type": "application/json",
    "Authorization": token ? `Bearer ${token}` : ""
  };
};

export const API = {
  async login(email, password) {
    const response = await fetch(`${API_BASE}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });
    
    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.message || "Authentication failed.");
    }
    
    const data = await response.json();
    localStorage.setItem("iod_jwt_token", data.token);
    localStorage.setItem("iod_active_user", JSON.stringify(data.user));
    return data.user;
  },

  logout() {
    localStorage.removeItem("iod_jwt_token");
    localStorage.removeItem("iod_active_user");
  },

  async getEmployees() {
    const response = await fetch(`${API_BASE}/admin/employees`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load employees.");
    return await response.json();
  },

  async getDuties() {
    const response = await fetch(`${API_BASE}/duty/active`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load active duties.");
    return await response.json();
  },

  async createEmployee(employee) {
    const response = await fetch(`${API_BASE}/admin/employees`, {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify(employee)
    });
    if (!response.ok) {
      let errorMessage = "Failed to create employee.";
      try {
        const err = await response.json();
        errorMessage = err.message || errorMessage;
      } catch (e) {
        if (response.status === 401) errorMessage = "Session expired. Please log in again.";
      }
      throw new Error(errorMessage);
    }
    return await response.json();
  },

  async getQr(employeeId) {
    const response = await fetch(`${API_BASE}/admin/employees/${employeeId}/get-qr`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to fetch QR token.");
    return await response.json();
  },

  async generateQr(employeeId) {
    const response = await fetch(`${API_BASE}/admin/employees/${employeeId}/generate-qr`, {
      method: "POST",
      headers: getHeaders()
    });
    if (!response.ok) {
      throw new Error("Failed to generate QR token.");
    }
    return await response.json();
  },

  async toggleEmployee(id) {
    const response = await fetch(`${API_BASE}/admin/employees/toggle/${id}`, {
      method: "POST",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to toggle employee status.");
    return await response.json();
  },

  async registerFace(id) {
    const response = await fetch(`${API_BASE}/admin/employees/register-face/${id}`, {
      method: "POST",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to register face template.");
    return await response.json();
  },

  async getActiveVisitors() {
    const response = await fetch(`${API_BASE}/visitor/active`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load active visitors.");
    return await response.json();
  },

  async getAllVisitors() {
    const response = await fetch(`${API_BASE}/visitor/all`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load all visitors.");
    return await response.json();
  },

  async checkoutVisitor(id) {
    const response = await fetch(`${API_BASE}/visitor/check-out/${id}`, {
      method: "POST",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to checkout visitor.");
    return await response.json();
  },

  async getWatchlist() {
    const response = await fetch(`${API_BASE}/admin/watchlist`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load watchlist.");
    return await response.json();
  },

  async addWatchlist(target) {
    const response = await fetch(`${API_BASE}/admin/watchlist`, {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify(target)
    });
    if (!response.ok) throw new Error("Failed to add target to watchlist.");
    return await response.json();
  },

  async removeWatchlist(id) {
    const response = await fetch(`${API_BASE}/admin/watchlist/${id}`, {
      method: "DELETE",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to remove watchlist target.");
    return await response.json();
  },

  async getAuditLogs() {
    const response = await fetch(`${API_BASE}/admin/logs`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load audit logs.");
    return await response.json();
  },
  
  async updateEmployee(id, employee) {
    const response = await fetch(`${API_BASE}/admin/employees/update/${id}`, {
      method: "POST",
      headers: getHeaders(),
      body: JSON.stringify(employee)
    });
    if (!response.ok) {
      const err = await response.json();
      throw new Error(err.message || "Failed to update employee.");
    }
    return await response.json();
  },

  async getAttendanceReport() {
    const response = await fetch(`${API_BASE}/admin/attendance-report`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load attendance report.");
    return await response.json();
  },

  async getVisitorReport() {
    const response = await fetch(`${API_BASE}/admin/visitor-report`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load visitor report.");
    return await response.json();
  },

  async getShiftReport() {
    const response = await fetch(`${API_BASE}/admin/shift-report`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load shift report.");
    return await response.json();
  },

  async getPendingGatePasses() {
    const response = await fetch(`${API_BASE}/gatepass/pending`, {
      method: "GET",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to load pending gate passes.");
    return await response.json();
  },

  async approveGatePass(id, approve) {
    const response = await fetch(`${API_BASE}/gatepass/approve/${id}?approve=${approve}`, {
      method: "POST",
      headers: getHeaders()
    });
    if (!response.ok) throw new Error("Failed to approve/reject gate pass.");
    return await response.json();
  }
};
