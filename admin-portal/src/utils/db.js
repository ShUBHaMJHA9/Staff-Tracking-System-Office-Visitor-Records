// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\admin-portal\src\utils\db.js

const INITIAL_EMPLOYEES = [
  {
    id: "emp-101",
    firstName: "Ravi Shankar",
    lastName: "Swami",
    email: "webmaster@iodglobal.com",
    phone: "+91-9773892127",
    department: "Web & IT",
    designation: "General Manager",
    role: "Admin",
    isActive: true,
    photoUrl: "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150",
    faceRegistered: true
  },
  {
    id: "emp-102",
    firstName: "Shubham",
    lastName: "Kumar",
    email: "shubham@iodglobal.com",
    phone: "+91-9876543210",
    department: "Web & IT",
    designation: "Software Engineering Intern",
    role: "Staff",
    isActive: true,
    photoUrl: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150",
    faceRegistered: true
  },
  {
    id: "emp-103",
    firstName: "Anita",
    lastName: "Sharma",
    email: "anita.hr@iodglobal.com",
    phone: "+91-9988776655",
    department: "Human Resources",
    designation: "HR Lead",
    role: "Staff",
    isActive: true,
    photoUrl: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150",
    faceRegistered: false
  },
  {
    id: "emp-104",
    firstName: "Satish",
    lastName: "Singh",
    email: "satish.guard@iodglobal.com",
    phone: "+91-9122334455",
    department: "Security Operations",
    designation: "Lobby Security Supervisor",
    role: "SecurityGuard",
    isActive: true,
    photoUrl: "https://images.unsplash.com/photo-1621574539437-4b7cb63120b8?w=150",
    faceRegistered: true
  }
];

const INITIAL_VISITORS = [
  {
    id: "visit-201",
    firstName: "Rajesh",
    lastName: "Kumar",
    email: "rajesh@client.com",
    phone: "+91-9898989898",
    company: "ABC Solutions Ltd",
    hostEmployeeId: "emp-101",
    hostName: "Ravi Shankar Swami",
    hostDepartment: "Web & IT",
    purpose: "Consultancy Project Review",
    status: "Checked In",
    checkInTime: "2026-06-26T14:15:00Z",
    checkOutTime: null,
    photoUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
    cardScanned: true
  },
  {
    id: "visit-202",
    firstName: "Meenakshi",
    lastName: "Patel",
    email: "meenakshi@tcs.com",
    phone: "+91-9776655443",
    company: "Tata Consultancy Services",
    hostEmployeeId: "emp-103",
    hostName: "Anita Sharma",
    hostDepartment: "Human Resources",
    purpose: "Vendor Placement Audit",
    status: "Pre-registered",
    checkInTime: null,
    checkOutTime: null,
    photoUrl: "",
    cardScanned: false
  },
  {
    id: "visit-203",
    firstName: "Vikram",
    lastName: "Rathore",
    email: "vikram@industryhub.org",
    phone: "+91-9444333222",
    company: "Industry Hub India",
    hostEmployeeId: "emp-101",
    hostName: "Ravi Shankar Swami",
    hostDepartment: "Web & IT",
    purpose: "Executive Board Sponsorship Discussion",
    status: "Checked Out",
    checkInTime: "2026-06-26T09:30:00Z",
    checkOutTime: "2026-06-26T12:00:00Z",
    photoUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
    cardScanned: true
  }
];

const INITIAL_OFFICE_DUTIES = [
  {
    id: "duty-301",
    employeeId: "emp-102",
    employeeName: "Shubham Kumar",
    destination: "Nehru Place Client Center",
    reason: "Hardware installation & website training for Directors",
    status: "Active",
    startTime: "2026-06-26T10:30:00Z",
    stopTime: null,
    coordinates: [
      { lat: 28.5494, lng: 77.2519, timestamp: "10:35 AM" },
      { lat: 28.5480, lng: 77.2525, timestamp: "10:45 AM" },
      { lat: 28.5471, lng: 77.2536, timestamp: "11:00 AM" },
      { lat: 28.5460, lng: 77.2550, timestamp: "11:30 AM" }
    ]
  }
];

const INITIAL_WATCHLIST = [
  {
    id: "wl-401",
    firstName: "Suresh",
    lastName: "Mehta",
    phone: "+91-9000111222",
    email: "suresh@blacklisted.com",
    reason: "Disruptive behavior during General Meeting",
    flaggedAt: "2026-05-10T11:00:00Z"
  }
];

const INITIAL_AUDIT_LOGS = [
  {
    id: "log-501",
    timestamp: "2026-06-26T14:15:00Z",
    user: "Satish Singh (Guard)",
    action: "Visitor Check-in",
    details: "Checked in Rajesh Kumar from ABC Solutions Ltd. Card scanned successfully.",
    severity: "info"
  },
  {
    id: "log-502",
    timestamp: "2026-06-26T14:02:11Z",
    user: "System",
    action: "GPS Office Duty Start",
    details: "Employee Shubham Kumar initiated out-of-office GPS Duty Tracking (Destination: Nehru Place).",
    severity: "info"
  },
  {
    id: "log-503",
    timestamp: "2026-06-26T13:46:00Z",
    user: "Admin",
    action: "Employee Creation",
    details: "Created new employee account for Anita Sharma (HR Lead).",
    severity: "info"
  }
];

export const DB = {
  init() {
    if (!localStorage.getItem("iod_employees")) {
      localStorage.setItem("iod_employees", JSON.stringify(INITIAL_EMPLOYEES));
    }
    if (!localStorage.getItem("iod_visitors")) {
      localStorage.setItem("iod_visitors", JSON.stringify(INITIAL_VISITORS));
    }
    if (!localStorage.getItem("iod_duties")) {
      localStorage.setItem("iod_duties", JSON.stringify(INITIAL_OFFICE_DUTIES));
    }
    if (!localStorage.getItem("iod_watchlist")) {
      localStorage.setItem("iod_watchlist", JSON.stringify(INITIAL_WATCHLIST));
    }
    if (!localStorage.getItem("iod_audit")) {
      localStorage.setItem("iod_audit", JSON.stringify(INITIAL_AUDIT_LOGS));
    }
  },

  getEmployees() {
    this.init();
    return JSON.parse(localStorage.getItem("iod_employees"));
  },

  saveEmployee(employee) {
    const list = this.getEmployees();
    const index = list.findIndex(e => e.id === employee.id);
    if (index >= 0) {
      list[index] = { ...list[index], ...employee };
    } else {
      list.push(employee);
    }
    localStorage.setItem("iod_employees", JSON.stringify(list));
    this.addAuditLog("Admin", "Employee Save", `Saved employee ${employee.firstName} ${employee.lastName} (${employee.designation}).`);
    return list;
  },

  toggleEmployeeStatus(id) {
    const list = this.getEmployees();
    const index = list.findIndex(e => e.id === id);
    if (index >= 0) {
      list[index].isActive = !list[index].isActive;
      localStorage.setItem("iod_employees", JSON.stringify(list));
      this.addAuditLog("Admin", "Employee Status Toggle", `Toggled status of employee ID ${id} to ${list[index].isActive ? "Active" : "Inactive"}.`);
    }
    return list;
  },

  getVisits() {
    this.init();
    return JSON.parse(localStorage.getItem("iod_visitors"));
  },

  saveVisit(visit) {
    const list = this.getVisits();
    const index = list.findIndex(v => v.id === visit.id);
    if (index >= 0) {
      list[index] = { ...list[index], ...visit };
    } else {
      list.push(visit);
    }
    localStorage.setItem("iod_visitors", JSON.stringify(list));
    return list;
  },

  getDuties() {
    this.init();
    return JSON.parse(localStorage.getItem("iod_duties"));
  },

  saveDuty(duty) {
    const list = this.getDuties();
    const index = list.findIndex(d => d.id === duty.id);
    if (index >= 0) {
      list[index] = { ...list[index], ...duty };
    } else {
      list.push(duty);
    }
    localStorage.setItem("iod_duties", JSON.stringify(list));
    return list;
  },

  getWatchlist() {
    this.init();
    return JSON.parse(localStorage.getItem("iod_watchlist"));
  },

  saveWatchlist(person) {
    const list = this.getWatchlist();
    const index = list.findIndex(p => p.id === person.id);
    if (index >= 0) {
      list[index] = { ...list[index], ...person };
    } else {
      list.push(person);
    }
    localStorage.setItem("iod_watchlist", JSON.stringify(list));
    this.addAuditLog("Admin", "Watchlist Update", `Added/Updated ${person.firstName} ${person.lastName} on security watchlist.`);
    return list;
  },

  removeWatchlist(id) {
    const list = this.getWatchlist();
    const filtered = list.filter(p => p.id !== id);
    localStorage.setItem("iod_watchlist", JSON.stringify(filtered));
    this.addAuditLog("Admin", "Watchlist Remove", `Removed item ID ${id} from security watchlist.`);
    return filtered;
  },

  getAuditLogs() {
    this.init();
    return JSON.parse(localStorage.getItem("iod_audit"));
  },

  addAuditLog(user, action, details, severity = "info") {
    this.init();
    const list = JSON.parse(localStorage.getItem("iod_audit")) || [];
    const newLog = {
      id: "log-" + Date.now(),
      timestamp: new Date().toISOString(),
      user,
      action,
      details,
      severity
    };
    list.unshift(newLog);
    localStorage.setItem("iod_audit", JSON.stringify(list.slice(0, 100))); // Cap at 100 entries
    return list;
  }
};
