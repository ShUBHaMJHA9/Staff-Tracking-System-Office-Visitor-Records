// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\admin-portal\src\components\AdminPortal.jsx
import React, { useState, useEffect, useRef } from 'react';
import { API } from '../utils/api';
import { 
  Users, UserCheck, ShieldAlert, Map, Plus, CreditCard, 
  Terminal, Search, ChevronRight, CheckCircle, RefreshCw, X,
  Printer, Ban, ShieldCheck, Clock, Navigation, AlertTriangle, Filter, Check, Eye, LogOut, Menu,
  Camera, Upload, MapPin, Info, Target, Navigation2, QrCode, Share2
} from 'lucide-react';
import LiveTrackingMap from './LiveTrackingMap';
import { useLocation, useNavigate } from 'react-router-dom';

const CoordinateAddress = ({ lat, lng }) => {
  const [address, setAddress] = useState(`${lat.toFixed(4)}, ${lng.toFixed(4)}`);
  useEffect(() => {
    fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`, {
      headers: { 'User-Agent': 'EnterpriseOMS/1.0' }
    })
      .then(res => res.json())
      .then(data => {
        if (data && data.display_name) {
          const parts = data.display_name.split(', ');
          setAddress(parts.slice(0, 3).join(', '));
        }
      })
      .catch(() => {});
  }, [lat, lng]);
  
  return (
    <a href={`https://www.google.com/maps?q=${lat},${lng}`} target="_blank" rel="noopener noreferrer" style={{ textDecoration: 'none', color: 'var(--brand-primary)', display: 'flex', alignItems: 'center', gap: '6px' }}>
      <MapPin size={12} style={{ flexShrink: 0 }} /> 
      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{address}</span>
    </a>
  );
};

export default function AdminPortal({ onLogout, theme = 'theme-light' }) {
  const navigate = useNavigate();
  const location = useLocation();
  const currentPath = location.pathname;
  
  const [employees, setEmployees] = useState([]);
  const [visits, setVisits] = useState([]);       // Active (checked-in) visitors for overview
  const [allVisits, setAllVisits] = useState([]); // All visitor records for Visitor Management tab
  const [watchlist, setWatchlist] = useState([]);
  const [auditLogs, setAuditLogs] = useState([]);
  const [pendingGatePasses, setPendingGatePasses] = useState([]);
  const [attendanceReport, setAttendanceReport] = useState([]);
  const [shiftReport, setShiftReport] = useState([]);
  
  // Search & Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [deptFilter, setDeptFilter] = useState('All');
  const [attSearchQuery, setAttSearchQuery] = useState('');
  const [attDateFilter, setAttDateFilter] = useState('');
  const [attRoleFilter, setAttRoleFilter] = useState('All');
  const [selectedCalendarDate, setSelectedCalendarDate] = useState(null);
  
  // Mobile responsive sidebar state
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

  const selectTab = (path) => {
    navigate(path);
    setMobileSidebarOpen(false);
  };
  
  // Modals & Panels
  const [showAddEmp, setShowAddEmp] = useState(false);
  const [showIDCard, setShowIDCard] = useState(null);
  const [showAddWatchlist, setShowAddWatchlist] = useState(false);
  const [faceRegisteringEmp, setFaceRegisteringEmp] = useState(null);
  const [faceProgress, setFaceProgress] = useState(0);
  const [editEmp, setEditEmp] = useState(null);
  const [selectedDutyInfo, setSelectedDutyInfo] = useState(null);

  // Camera & Image Upload States
  const [showCameraModal, setShowCameraModal] = useState(false);
  const [isEditCamera, setIsEditCamera] = useState(false);
  const [cameraActive, setCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState(false);
  const videoRef = useRef(null);
  const canvasRef = useRef(null);

  const mockFaces = [
    { name: "Executive Director (Male)", url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150" },
    { name: "Senior Analyst (Female)", url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150" },
    { name: "IT Administrator (Male)", url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150" },
    { name: "HR Manager (Female)", url: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150" },
    { name: "Board Secretary (Female)", url: "https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150" },
    { name: "Security Specialist (Male)", url: "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150" }
  ];
  const [selectedMockFace, setSelectedMockFace] = useState(mockFaces[0].url);

  // Form States
  const [newEmp, setNewEmp] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    department: 'Web & IT',
    designation: '',
    role: 'Staff',
    photoUrl: ''
  });

  const [newWl, setNewWl] = useState({
    firstName: '',
    lastName: '',
    phone: '',
    email: '',
    reason: ''
  });

  // Live duty coordinates tracking state from DB
  const [duties, setDuties] = useState([]);

  // Load Data from C# Backend APIs
  const loadDbState = async () => {
    try {
      const empList = await API.getEmployees();
      setEmployees(empList);
      
      const vList = await API.getActiveVisitors();
      setVisits(vList);

      try {
        const allVList = await API.getAllVisitors();
        setAllVisits(allVList);
      } catch {
        // Fallback: use active visits if all-visitors endpoint not ready
        setAllVisits(vList);
      }
      
      const wlList = await API.getWatchlist();
      setWatchlist(wlList);
      
      const logList = await API.getAuditLogs();
      setAuditLogs(logList);

      try {
        const dList = await API.getDuties();
        setDuties(dList);
      } catch (err) {
        console.warn("Could not load duties:", err);
      }

      try {
        const gps = await API.getPendingGatePasses();
        setPendingGatePasses(gps);
      } catch (err) {
        console.warn("Could not load pending gate passes:", err);
      }

      try {
        const att = await API.getAttendanceReport();
        setAttendanceReport(att);
      } catch (err) {
        console.warn("Could not load attendance report:", err);
      }

      try {
        const shifts = await API.getShiftReport();
        setShiftReport(shifts);
      } catch (err) {
        console.warn("Could not load shift report:", err);
      }
    } catch (err) {
      console.error("Failed to load live database state:", err);
    }
  };

  useEffect(() => {
    loadDbState();
    // Auto-update GPS path movement for active duties to simulate live tracking
    const interval = setInterval(() => {
      setDuties(prevDuties => {
        return prevDuties.map(d => {
          if (d.status === 'Active') {
            const lastCoord = d.coordinates[d.coordinates.length - 1] || { lat: 28.5494, lng: 77.2519 };
            const newLat = lastCoord.lat + (Math.random() - 0.5) * 0.001;
            const newLng = lastCoord.lng + (Math.random() - 0.5) * 0.001;
            const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            return {
              ...d,
              coordinates: [...d.coordinates, { lat: newLat, lng: newLng, timestamp: now }].slice(-10)
            };
          }
          return d;
        });
      });
    }, 4000);

    // Auto-poll database state every 10 seconds (Background Auto-Sync)
    const dbInterval = setInterval(() => {
      loadDbState();
    }, 10000);

    return () => {
      clearInterval(interval);
      clearInterval(dbInterval);
    };
  }, []);

  const handleAddEmployee = async (e) => {
    e.preventDefault();
    const employee = {
      firstName: newEmp.firstName,
      lastName: newEmp.lastName,
      email: newEmp.email,
      phone: newEmp.phone,
      department: newEmp.department,
      designation: newEmp.designation,
      role: newEmp.role,
      photoUrl: newEmp.photoUrl
    };
    try {
      await API.createEmployee(employee);
      setNewEmp({
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        department: 'Web & IT',
        designation: '',
        role: 'Staff',
        photoUrl: ''
      });
      setShowAddEmp(false);
      loadDbState();
    } catch (err) {
      alert(err.message || "Failed to create employee.");
    }
  };

  const handleProcessGatePass = async (id, approve) => {
    try {
      await API.approveGatePass(id, approve);
      loadDbState();
    } catch (err) {
      alert("Failed to process gate pass: " + err.message);
    }
  };

  const handleUpdateEmployee = async (e) => {
    e.preventDefault();
    const employee = {
      firstName: editEmp.firstName,
      lastName: editEmp.lastName,
      email: editEmp.email,
      phone: editEmp.phone,
      department: editEmp.department,
      designation: editEmp.designation,
      role: editEmp.role,
      photoUrl: editEmp.photoUrl
    };
    try {
      await API.updateEmployee(editEmp.id, employee);
      setEditEmp(null);
      loadDbState();
    } catch (err) {
      alert(err.message || "Failed to update employee.");
    }
  };

  const handlePhotoUpload = (e, isEdit) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        if (isEdit) {
          setEditEmp(prev => ({ ...prev, photoUrl: reader.result }));
        } else {
          setNewEmp(prev => ({ ...prev, photoUrl: reader.result }));
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const startCamera = async (isEdit) => {
    setIsEditCamera(isEdit);
    setShowCameraModal(true);
    setCameraActive(true);
    setCameraError(false);
    
    // Give state a tick to mount the video element
    setTimeout(async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: { width: 320, height: 320, facingMode: 'user' } 
        });
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
        }
      } catch (err) {
        console.warn("Hardware camera unavailable, using matrix sweep mode:", err);
        setCameraError(true);
      }
    }, 100);
  };

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const tracks = videoRef.current.srcObject.getTracks();
      tracks.forEach(track => track.stop());
      videoRef.current.srcObject = null;
    }
    setCameraActive(false);
    setShowCameraModal(false);
  };

  const capturePhoto = () => {
    if (cameraActive && !cameraError && videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      const context = canvas.getContext('2d');
      canvas.width = video.videoWidth || 320;
      canvas.height = video.videoHeight || 320;
      context.drawImage(video, 0, 0, canvas.width, canvas.height);
      const dataUrl = canvas.toDataURL('image/jpeg');
      if (isEditCamera) {
        setEditEmp(prev => ({ ...prev, photoUrl: dataUrl }));
      } else {
        setNewEmp(prev => ({ ...prev, photoUrl: dataUrl }));
      }
    } else {
      // Simulate capture using mock face selection
      if (isEditCamera) {
        setEditEmp(prev => ({ ...prev, photoUrl: selectedMockFace }));
      } else {
        setNewEmp(prev => ({ ...prev, photoUrl: selectedMockFace }));
      }
    }
    stopCamera();
  };

  const handleQuickUpload = async (e, emp) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64Photo = reader.result;
        try {
          const updatedEmp = {
            firstName: emp.firstName,
            lastName: emp.lastName,
            email: emp.email,
            phone: emp.phone || '',
            department: emp.department,
            designation: emp.designation,
            role: emp.role,
            photoUrl: base64Photo
          };
          await API.updateEmployee(emp.id, updatedEmp);
          loadDbState();
        } catch (err) {
          alert("Failed to upload photo to server: " + err.message);
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const handleToggleEmp = async (id) => {
    try {
      await API.toggleEmployee(id);
      loadDbState();
    } catch (err) {
      console.error(err);
    }
  };

  const startFaceRegistration = (emp) => {
    setFaceRegisteringEmp(emp);
    setFaceProgress(0);
    const interval = setInterval(() => {
      setFaceProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setTimeout(async () => {
            try {
              await API.registerFace(emp.id);
              setFaceRegisteringEmp(null);
              loadDbState();
            } catch (err) {
              console.error(err);
              setFaceRegisteringEmp(null);
            }
          }, 500);
          return 100;
        }
        return prev + 25;
      });
    }, 600);
  };

  const handleAddWatchlist = async (e) => {
    e.preventDefault();
    const entry = {
      firstName: newWl.firstName,
      lastName: newWl.lastName,
      phone: newWl.phone,
      email: newWl.email,
      reason: newWl.reason
    };
    try {
      await API.addWatchlist(entry);
      setNewWl({ firstName: '', lastName: '', phone: '', email: '', reason: '' });
      setShowAddWatchlist(false);
      await loadDbState();
    } catch (e) {
      alert(e.message);
    }
  };

  const shareLoginQr = async (empId) => {
    try {
      const res = await API.getQr(empId); // GET existing token — does NOT invalidate it
      const text = `IOD Gatekeeper Mobile App Login\n\nYour secure QR Login Token is:\n${res.qrToken}\n\nPlease copy this token and enter it in the app to authenticate.`;
      const url = `https://wa.me/?text=${encodeURIComponent(text)}`;
      window.open(url, '_blank');
    } catch (e) {
      alert(e.message);
    }
  };

  const handleRemoveWatchlist = async (id) => {
    try {
      await API.removeWatchlist(id);
      loadDbState();
    } catch (err) {
      console.error(err);
    }
  };

  const forceCheckout = async (visit) => {
    try {
      await API.checkoutVisitor(visit.id);
      loadDbState();
    } catch (err) {
      console.error(err);
    }
  };

  // Filtered lists for Attendance Report
  const filteredAttendance = attendanceReport.filter(a => {
    const fullName = `${a.user?.firstName || ''} ${a.user?.lastName || ''}`.toLowerCase();
    if (attSearchQuery && !fullName.includes(attSearchQuery.toLowerCase())) return false;
    
    if (attRoleFilter !== 'All' && a.user?.role !== attRoleFilter) return false;
    
    if (attDateFilter) {
      const checkInDate = new Date(a.checkIn).toISOString().split('T')[0];
      if (checkInDate !== attDateFilter) return false;
    }
    return true;
  });

  const filteredShifts = shiftReport.filter(s => {
    const fullName = `${s.user?.firstName || ''} ${s.user?.lastName || ''}`.toLowerCase();
    if (attSearchQuery && !fullName.includes(attSearchQuery.toLowerCase())) return false;
    
    if (attDateFilter) {
      const checkInDate = new Date(s.checkIn).toISOString().split('T')[0];
      if (checkInDate !== attDateFilter) return false;
    }
    return true;
  });

  const renderAttendanceCalendar = () => {
    const today = new Date();
    const year = today.getFullYear();
    const month = today.getMonth(); // 0-indexed
    const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    
    // Days in month
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const firstDayIndex = new Date(year, month, 1).getDay(); // Day of week index
    
    // Calculate check-in densities (e.g. checkins count per day)
    const densityMap = {};
    attendanceReport.forEach(a => {
      const date = new Date(a.checkIn);
      if (date.getFullYear() === year && date.getMonth() === month) {
        const dayNum = date.getDate();
        densityMap[dayNum] = (densityMap[dayNum] || 0) + 1;
      }
    });
    
    const days = [];
    // Empty slots before first day
    for (let i = 0; i < firstDayIndex; i++) {
      days.push(<div key={`empty-${i}`} className="calendar-day-tile empty"></div>);
    }
    
    // Real days
    for (let d = 1; d <= daysInMonth; d++) {
      const isToday = today.getDate() === d && today.getMonth() === month && today.getFullYear() === year;
      const isSelected = selectedCalendarDate === d;
      const count = densityMap[d] || 0;
      
      days.push(
        <div 
          key={`day-${d}`} 
          className={`calendar-day-tile ${isToday ? 'today' : ''} ${isSelected ? 'selected' : count > 5 ? 'density-high' : count > 2 ? 'density-medium' : count > 0 ? 'density-low' : ''}`}
          onClick={() => {
            if (isSelected) {
              setSelectedCalendarDate(null);
              setAttDateFilter('');
            } else {
              setSelectedCalendarDate(d);
              const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
              setAttDateFilter(dateStr);
            }
          }}
        >
          <span style={{ fontSize: '13px', fontWeight: 'bold' }}>{d}</span>
          {count > 0 && (
            <span style={{ fontSize: '10px', fontWeight: '600', padding: '2px 6px', borderRadius: '4px', alignSelf: 'flex-end', backgroundColor: isSelected ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.06)' }}>
              {count} checks
            </span>
          )}
        </div>
      );
    }
    
    return (
      <div className="panel" style={{ marginBottom: 24, padding: 20 }}>
        <div className="panel-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div>
            <h5 style={{ margin: 0, fontSize: '16px', fontWeight: 700 }}>{monthNames[month]} {year} — Live Sentry Check-In Density Map</h5>
            <p className="subtitle" style={{ margin: '4px 0 0' }}>Interactive calendar grid highlighting overall facility entries & outdoor guard deployments</p>
          </div>
          {selectedCalendarDate && (
            <button 
              className="btn btn-sm btn-outline" 
              onClick={() => { setSelectedCalendarDate(null); setAttDateFilter(''); }}
              style={{ fontSize: '12px', padding: '6px 12px', borderRadius: 6 }}
            >
              Clear Filter
            </button>
          )}
        </div>
        <div>
          <div className="calendar-grid-header" style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 8, textAlign: 'center', fontWeight: '700', fontSize: '12px', marginBottom: 12, color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            <div>Sun</div><div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div><div>Fri</div><div>Sat</div>
          </div>
          <div className="calendar-container">
            {days}
          </div>
        </div>
      </div>
    );
  };

  // Filter Logic
  const filteredEmployees = employees.filter(emp => {
    const fullName = `${emp.firstName} ${emp.lastName}`.toLowerCase();
    const query = searchQuery.toLowerCase();
    const matchQuery = fullName.includes(query) || (emp.email || '').toLowerCase().includes(query) || (emp.designation || '').toLowerCase().includes(query);
    const matchDept = deptFilter === 'All' || emp.department === deptFilter;
    return matchQuery && matchDept;
  });

  return (
    <div className="admin-container">
      {/* Mobile Top Header (Sticky) */}
      <div className="mobile-top-bar">
        <button className="menu-toggle-btn" onClick={() => setMobileSidebarOpen(true)}>
          <Menu size={22} />
        </button>
        <div className="mobile-brand-title">IOD Admin Console</div>
        <div style={{ width: 22 }}></div> {/* Spacer to center title */}
      </div>

      {/* Background Overlay when Sidebar is open on mobile */}
      {mobileSidebarOpen && (
        <div className="sidebar-mobile-overlay" onClick={() => setMobileSidebarOpen(false)}></div>
      )}

      {/* Sidebar Navigation */}
      <aside className={`admin-sidebar ${mobileSidebarOpen ? 'open' : ''} ${isSidebarCollapsed ? 'collapsed' : ''}`}>
        <div className="sidebar-brand">
          <div className="brand-logo" onClick={() => setIsSidebarCollapsed(!isSidebarCollapsed)} style={{ cursor: 'pointer', userSelect: 'none' }} title="Toggle Sidebar collapse">IOD</div>
          {!isSidebarCollapsed && (
            <div className="brand-text">
              <h4>INSTITUTE OF DIRECTORS</h4>
              <span>Enterprise OMS</span>
            </div>
          )}
          <button className="sidebar-close-btn" onClick={() => setMobileSidebarOpen(false)}>
            <X size={18} />
          </button>
        </div>

        <nav className="sidebar-menu">
          <button 
            className={`menu-item ${currentPath === '/dashboard' || currentPath === '/' ? 'active' : ''}`}
            onClick={() => selectTab('/dashboard')}
            title="Overview Dashboard"
          >
            <Users size={18} />
            {!isSidebarCollapsed && <span>Overview Dashboard</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/directory' ? 'active' : ''}`}
            onClick={() => selectTab('/directory')}
            title="Employee Directory"
          >
            <UserCheck size={18} />
            {!isSidebarCollapsed && <span>Employee Directory</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/visitors' ? 'active' : ''}`}
            onClick={() => selectTab('/visitors')}
            title="Visitor Management"
          >
            <CreditCard size={18} />
            {!isSidebarCollapsed && <span>Visitor Management</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/map' ? 'active' : ''}`}
            onClick={() => selectTab('/map')}
            title="Live Field Tracking"
          >
            <Map size={18} />
            {!isSidebarCollapsed && <span>Live Field Tracking</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/watchlist' ? 'active' : ''}`}
            onClick={() => selectTab('/watchlist')}
            title="Watchlist Rules"
          >
            <ShieldAlert size={18} />
            {!isSidebarCollapsed && <span>Watchlist Rules</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/logs' ? 'active' : ''}`}
            onClick={() => selectTab('/logs')}
            title="System Audit Logs"
          >
            <Terminal size={18} />
            {!isSidebarCollapsed && <span>System Audit Logs</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/attendance' ? 'active' : ''}`}
            onClick={() => selectTab('/attendance')}
            title="Attendance & Shifts"
          >
            <Clock size={18} />
            {!isSidebarCollapsed && <span>Attendance & Shifts</span>}
          </button>
          <button 
            className={`menu-item ${currentPath === '/gatepasses' ? 'active' : ''}`}
            onClick={() => selectTab('/gatepasses')}
            title="Gate Pass Approvals"
          >
            <CheckCircle size={18} />
            {!isSidebarCollapsed && <span>Gate Pass Approvals ({pendingGatePasses.length})</span>}
          </button>
        </nav>

        <div className="sidebar-footer">
          <div className="user-profile-badge">
            <div className="avatar">A</div>
            {!isSidebarCollapsed && (
              <div className="details">
                <h6>Super Administrator</h6>
                <span>admin@iod.com</span>
              </div>
            )}
          </div>
          {onLogout && (
            <button className="btn-logout" onClick={onLogout} style={{ marginTop: '12px', width: isSidebarCollapsed ? 'auto' : '100%', padding: isSidebarCollapsed ? '8px' : '8px 12px' }}>
              <LogOut size={12} className={isSidebarCollapsed ? '' : 'mr-1'} />
              {!isSidebarCollapsed && "Sign Out Session"}
            </button>
          )}
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="admin-content">
        <header className="content-header">
          <div className="header-title">
            <h2>
              {currentPath === '/directory' ? 'Employee Directory' : 
               currentPath === '/visitors' ? 'Visitor Management' :
               currentPath === '/map' ? 'Fleet & Personnel GPS Tracking' :
               currentPath === '/watchlist' ? 'Visitor Watchlist Rules' :
               currentPath === '/logs' ? 'System Audit Logs' : 
               currentPath === '/attendance' ? 'Attendance & Shifts Report' :
               currentPath === '/gatepasses' ? 'Gate Pass Approvals' : 'Overview Dashboard'}
            </h2>
            <p>
              {currentPath === '/directory' ? 'Manage staff accounts, profiles, and register Face ID biometric parameters' : 
               currentPath === '/visitors' ? 'Complete visitor log roster — check-ins, check-outs, and pre-registrations' :
               currentPath === '/map' ? 'Real-time logistics tracking via OpenStreetMap — click a marker for details' :
               currentPath === '/watchlist' ? 'Security gate block rules and restricted visitor management' :
               currentPath === '/logs' ? 'Real-time systemic actions & security triggers' : 
               currentPath === '/attendance' ? 'View all staff attendance logs and guard shift records' :
               currentPath === '/gatepasses' ? 'Manage, approve, or reject early leave request tokens' : 'Institute of Directors (IOD) - Core Administration Panel'}
            </p>
          </div>
        </header>

        <div className="content-body">
        {/* 1. OVERVIEW DASHBOARD */}
        {(currentPath === '/' || currentPath === '/dashboard') && (
          <div className="tab-pane">
            <div className="dashboard-hero">
              <div>
                <h2>Global Command Center</h2>
                <p>Monitor real-time facility operations, staff deployments, and security events across all sectors.</p>
              </div>
            </div>

            <div className="metrics-grid">
              <div className="metric-card card-staff">
                <div className="icon-wrapper">
                  <UserCheck size={24} />
                </div>
                <div className="stats">
                  <h3>{employees.filter(e => e.isActive).length}</h3>
                  <p>Active Staff</p>
                </div>
              </div>
              <div className="metric-card card-visitors">
                <div className="icon-wrapper">
                  <CreditCard size={24} />
                </div>
                <div className="stats">
                  <h3>{visits.filter(v => v.status === 'Checked In').length}</h3>
                  <p>Active Visitors Inside</p>
                </div>
              </div>
              <div className="metric-card card-duties">
                <div className="icon-wrapper">
                  <Map size={24} />
                </div>
                <div className="stats">
                  <h3>{duties.filter(d => d.status === 'Active').length}</h3>
                  <p>Staff On Field Duty</p>
                </div>
              </div>
              <div className="metric-card card-watchlist">
                <div className="icon-wrapper">
                  <ShieldAlert size={24} />
                </div>
                <div className="stats">
                  <h3>{watchlist.length}</h3>
                  <p>Watchlist Targets</p>
                </div>
              </div>
            </div>

            <div className="dashboard-layout">
              {/* Active Visitors Table */}
              <div className="panel flex-2">
                <div className="panel-header flex-row justify-between items-center">
                  <div>
                    <h5>Visitors Currently in Premises</h5>
                    <p className="subtitle">Real-time gate pass log ledger</p>
                  </div>
                  <span className="live-radar-ping">
                    <span className="ping-dot"></span>
                    Live Sync
                  </span>
                </div>
                <div className="table-responsive">
                  {visits.filter(v => v.status === 'Checked In').length === 0 ? (
                    <div className="premium-empty-state">
                      <div className="empty-icon-pulse">
                        <ShieldCheck size={40} />
                      </div>
                      <h5>Lobby Secure & Clear</h5>
                      <p>All registered visitors have completed checkout. The gate log is currently empty.</p>
                      <span className="badge-clear">Status: Clear</span>
                    </div>
                  ) : (
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Visitor Name & Company</th>
                          <th>Meeting Host</th>
                          <th>Check-in Time</th>
                          <th>Purpose</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {visits.filter(v => v.status === 'Checked In').map(v => (
                          <tr key={v.id}>
                            <td>
                              <div className="visitor-meta">
                                <strong className="name">{v.firstName} {v.lastName}</strong>
                                <span className="company">{v.company}</span>
                              </div>
                            </td>
                            <td>
                              <div className="host-details">
                                <span className="host-name">{v.hostName}</span>
                                <span className="host-dept">{v.hostDepartment}</span>
                              </div>
                            </td>
                            <td>
                              <div className="time-badge">
                                <Clock size={12} />
                                <span>{new Date(v.checkInTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                              </div>
                            </td>
                            <td><span className="badge-purpose">{v.purpose}</span></td>
                            <td>
                              <button className="btn btn-sm btn-outline-red" onClick={() => forceCheckout(v)}>
                                Force Checkout
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              </div>

              {/* Quick Security Logs feed */}
              <div className="panel panel-logs flex-1">
                <div className="panel-header">
                  <div>
                    <h5>Intelligence & Audit Logs</h5>
                    <p className="subtitle">Real-time systemic actions & security triggers</p>
                  </div>
                </div>
                <div className="log-list log-list-premium">
                  {auditLogs.slice(0, 4).map(l => (
                    <div className="log-feed-item" key={l.id}>
                      <div className="header">
                        <span className="log-action">{l.action}</span>
                        <span className="log-time">{new Date(l.timestamp).toLocaleTimeString()}</span>
                      </div>
                      <p className="log-desc">{l.details}</p>
                      <div className="actor">Authorized Actor: {l.user}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

          </div>
        )}

        {/* 2. EMPLOYEE DIRECTORY */}
        {currentPath === '/directory' && (
          <div className="tab-pane">
            <div className="filter-bar">
              <div className="search-box">
                <Search size={16} />
                <input 
                  type="text" 
                  placeholder="Search employees by name, email or title..." 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
              <div className="filters">
                <div className="filter-select">
                  <Filter size={14} />
                  <select value={deptFilter} onChange={(e) => setDeptFilter(e.target.value)}>
                    <option value="All">All Departments</option>
                    <option value="Web & IT">Web & IT</option>
                    <option value="Human Resources">Human Resources</option>
                    <option value="Security Operations">Security Operations</option>
                    <option value="Facilities Management">Facilities Management</option>
                    <option value="Finance & Accounting">Finance & Accounting</option>
                    <option value="Corporate Affairs">Corporate Affairs</option>
                  </select>
                </div>
                <button className="btn btn-primary" onClick={() => setShowAddEmp(true)}>
                  <Plus size={16} />
                  <span>Add Employee</span>
                </button>
              </div>
            </div>

            <div className="grid-list">
              {filteredEmployees.map(emp => (
                <div className={`card employee-card ${!emp.isActive ? 'inactive' : ''}`} key={emp.id}>
                  <div className="card-header-profile">
                    <img src={emp.photoUrl} alt="" className="profile-img" />
                    <div className="meta">
                      <h4>{emp.firstName} {emp.lastName}</h4>
                      <p>{emp.designation}</p>
                      <span className="dept-pill">{emp.department}</span>
                    </div>
                  </div>
                  <div className="card-body">
                    <div className="info-row">
                      <span>Email:</span>
                      <strong>{emp.email}</strong>
                    </div>
                    <div className="info-row">
                      <span>Phone:</span>
                      <strong>{emp.phone}</strong>
                    </div>
                    <div className="info-row">
                      <span>Biometric Face Lock:</span>
                      <strong>
                        {emp.faceRegistered ? (
                          <span className="status-pill status-active"><ShieldCheck size={12} /> Enrolled</span>
                        ) : (
                          <span className="status-pill status-warn"><AlertTriangle size={12} /> Pending</span>
                        )}
                      </strong>
                    </div>
                    <div className="info-row" style={{ marginTop: '10px', paddingTop: '10px', borderTop: '1px solid var(--border-subtle)' }}>
                      <span>Device Status:</span>
                      <strong>
                        {emp.isDeviceRegistered ? (
                          <span className="status-pill status-active"><CheckCircle size={12} /> Bound</span>
                        ) : (
                          <span className="status-pill status-inactive"><AlertTriangle size={12} /> Unregistered</span>
                        )}
                      </strong>
                    </div>
                    {!emp.isDeviceRegistered && emp.activationCode && (
                      <div className="info-row" style={{ marginTop: '4px' }}>
                        <span>Activation Code:</span>
                        <strong style={{ fontFamily: 'monospace', background: 'var(--bg-tertiary)', padding: '2px 6px', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
                          {emp.activationCode}
                        </strong>
                      </div>
                    )}
                  </div>
                  <div className="card-actions">
                    <button className="btn btn-secondary btn-sm" onClick={() => setShowIDCard(emp)} title="View Badge">
                      <CreditCard size={14} /> ID Card
                    </button>
                    <button className="btn btn-outline btn-sm" onClick={() => setEditEmp(emp)}>
                      Edit Profile
                    </button>
                    {!emp.faceRegistered && (
                      <button className="btn btn-outline btn-sm" onClick={() => startFaceRegistration(emp)}>
                        Enroll Face
                      </button>
                    )}
                    <button 
                      className={`btn btn-sm ${emp.isActive ? 'btn-outline-red' : 'btn-outline-green'}`} 
                      onClick={() => handleToggleEmp(emp.id)}
                    >
                      {emp.isActive ? "Deactivate" : "Activate"}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 3. VISITOR MANAGEMENT */}
        {currentPath === '/visitors' && (
          <div className="tab-pane">
            {/* Summary badges */}
            <div className="metrics-grid" style={{ marginBottom: '20px' }}>
              <div className="metric-card">
                <div className="icon-wrapper bg-green"><Eye size={22} /></div>
                <div className="stats">
                  <h3>{allVisits.filter(v => v.status === 'Checked In').length}</h3>
                  <p>Currently Inside</p>
                </div>
              </div>
              <div className="metric-card">
                <div className="icon-wrapper bg-blue"><CheckCircle size={22} /></div>
                <div className="stats">
                  <h3>{allVisits.filter(v => v.status === 'Checked Out').length}</h3>
                  <p>Checked Out Today</p>
                </div>
              </div>
              <div className="metric-card">
                <div className="icon-wrapper bg-yellow"><Clock size={22} /></div>
                <div className="stats">
                  <h3>{allVisits.filter(v => v.status === 'Pre-registered').length}</h3>
                  <p>Pre-registered</p>
                </div>
              </div>
              <div className="metric-card">
                <div className="icon-wrapper bg-red"><ShieldAlert size={22} /></div>
                <div className="stats">
                  <h3>{allVisits.length}</h3>
                  <p>Total Visitor Log</p>
                </div>
              </div>
            </div>

            <div className="panel">
              <div className="panel-header flex-row justify-between items-center">
                <div>
                  <h5>Complete Visitor Log Roster</h5>
                  <p className="subtitle">All visitor records — check-ins, check-outs, and pre-registrations</p>
                </div>
                <span className="live-radar-ping">
                  <span className="ping-dot"></span>
                  Lobby Gate Online
                </span>
              </div>
              <div className="table-responsive" style={{ margin: 0, border: 'none', borderRadius: 0 }}>
                {allVisits.length === 0 ? (
                  <div className="premium-empty-state">
                    <div className="empty-icon-pulse">
                      <ShieldCheck size={40} />
                    </div>
                    <h5>No Visitor Records Found</h5>
                    <p>Visitors checked in via the Guard Console will appear here in real time.</p>
                    <span className="badge-clear">GATE LOG: EMPTY</span>
                  </div>
                ) : (
                  <table className="table">
                    <thead>
                      <tr>
                        <th>Visitor Details</th>
                        <th>Company</th>
                        <th>Meeting Host</th>
                        <th>Check-in / Check-out</th>
                        <th>Entry Method</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {allVisits.map(v => (
                        <tr key={v.id}>
                          <td>
                            <div className="visitor-meta">
                              <strong className="name">{v.firstName} {v.lastName}</strong>
                              <span className="company">{v.email}</span>
                              <span style={{ fontSize: '11px', color: 'var(--text-mute)' }}>{v.phone}</span>
                            </div>
                          </td>
                          <td><span style={{ fontWeight: 500 }}>{v.company}</span></td>
                          <td>
                            <div className="host-details">
                              <span className="host-name">{v.hostName}</span>
                              <span className="host-dept">{v.hostDepartment}</span>
                            </div>
                          </td>
                          <td>
                            <div className="visit-times">
                              <div><Clock size={11} style={{ verticalAlign: 'middle', marginRight: 3 }} />In: {v.checkInTime ? new Date(v.checkInTime).toLocaleString() : '—'}</div>
                              <div><Clock size={11} style={{ verticalAlign: 'middle', marginRight: 3 }} />Out: {v.checkOutTime ? new Date(v.checkOutTime).toLocaleString() : <em style={{ color: 'var(--text-mute)' }}>Pending</em>}</div>
                            </div>
                          </td>
                          <td>
                            {v.cardScanned ? (
                              <span className="badge-ocr"><CheckCircle size={10} /> OCR Card</span>
                            ) : (
                              <span className="badge-manual">Manual Entry</span>
                            )}
                          </td>
                          <td>
                            <span className={`status-pill ${
                              v.status === 'Checked In' ? 'status-active' :
                              v.status === 'Pre-registered' ? 'status-warn' : 'status-inactive'
                            }`}>
                              {v.status}
                            </span>
                          </td>
                          <td>
                            {v.status === 'Checked In' && (
                              <button className="btn btn-sm btn-outline-red" onClick={() => forceCheckout(v)}>
                                Force Checkout
                              </button>
                            )}
                            {v.status !== 'Checked In' && (
                              <span style={{ color: 'var(--text-mute)', fontSize: '12px' }}>—</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        )}

        {/* 4. LIVE FIELD TRACKING */}
        {currentPath === '/map' && (
          <div className="tab-pane">
            <div className="tracking-split">
              {/* Sidebar with active duties */}
              <div className="tracking-sidebar panel">
                <div className="panel-header">
                  <h5>Active Field Assignments</h5>
                </div>
                <div className="duty-list">
                  {duties.filter(d => d.status === 'Active').length === 0 ? (
                    <div className="text-center text-muted py-4">No personnel currently dispatched on field assignments.</div>
                  ) : (
                    duties.filter(d => d.status === 'Active').map(d => (
                      <div className="duty-item active" key={d.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', borderBottom: '1px solid var(--border-subtle)' }}>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                            <h6 style={{ margin: 0, fontSize: '14.5px' }}>{d.employeeName}</h6>
                          </div>
                          <div style={{ fontSize: '12px', color: 'var(--text-mute)' }}>ID: EMP-{d.employeeId.substring(0, 4).toUpperCase()}</div>
                        </div>
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button 
                            className="btn btn-sm btn-outline" 
                            onClick={() => setSelectedDutyInfo(d)} 
                            style={{ padding: '6px', width: '34px', height: '34px', display: 'flex', justifyContent: 'center', alignItems: 'center' }} 
                            title="Duty Details"
                          >
                            <Info size={16} style={{ margin: 0 }} />
                          </button>
                          <a 
                            href={(d.coordinates || d.Coordinates || []).filter(c => (c.lat ?? c.latitude ?? c.Latitude) != null && (c.lng ?? c.longitude ?? c.Longitude) != null).length > 1 
                              ? `https://www.google.com/maps/dir/${(d.coordinates || d.Coordinates || []).filter(c => (c.lat ?? c.latitude ?? c.Latitude) != null).map(c => `${c.lat || c.latitude || c.Latitude},${c.lng || c.longitude || c.Longitude}`).join('/')}` 
                              : `https://www.google.com/maps?q=${(d.coordinates || d.Coordinates || [])?.[0]?.lat || (d.coordinates || d.Coordinates || [])?.[0]?.latitude || (d.coordinates || d.Coordinates || [])?.[0]?.Latitude},${(d.coordinates || d.Coordinates || [])?.[0]?.lng || (d.coordinates || d.Coordinates || [])?.[0]?.longitude || (d.coordinates || d.Coordinates || [])?.[0]?.Longitude}`}
                            target="_blank" 
                            rel="noopener noreferrer"
                            className="btn btn-sm btn-outline-green"
                            style={{ padding: '6px', width: '34px', height: '34px', display: 'flex', justifyContent: 'center', alignItems: 'center', textDecoration: 'none' }}
                            title="View Full Travel Route on Google Maps"
                          >
                            <MapPin size={16} style={{ margin: 0 }} />
                          </a>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Real Leaflet Map Panel */}
              <div className="tracking-map-container panel" style={{ minHeight: 500, height: '100%', overflow: 'hidden' }}>
                <div style={{ height: '100%', minHeight: 500 }}>
                  <LiveTrackingMap duties={duties} theme={theme} />
                </div>
              </div>
            </div>
          </div>
        )}

        {/* 5. WATCHLIST RULES */}
        {currentPath === '/watchlist' && (
          <div className="tab-pane">
            <div className="filter-bar">
              <h5 className="m-0">Visitor Watchlist Rules</h5>
              <button className="btn btn-primary" onClick={() => setShowAddWatchlist(true)}>
                <Ban size={16} />
                <span>Add to Watchlist</span>
              </button>
            </div>

            <div className="panel">
              <div className="table-responsive">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Email / Contact</th>
                      <th>Flag Reason</th>
                      <th>Date Enforced</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {watchlist.length === 0 ? (
                      <tr>
                        <td colSpan="5" className="text-center text-muted py-4">No individuals currently on the watchlist.</td>
                      </tr>
                    ) : (
                      watchlist.map(wl => (
                        <tr key={wl.id}>
                          <td><strong>{wl.firstName} {wl.lastName}</strong></td>
                          <td>{wl.email} | {wl.phone}</td>
                          <td>
                            <span className="text-red flex-align-center">
                              <AlertTriangle size={14} className="mr-1" />
                              {wl.reason}
                            </span>
                          </td>
                          <td>{new Date(wl.flaggedAt).toLocaleString()}</td>
                          <td>
                            <button className="btn btn-sm btn-outline-green" onClick={() => handleRemoveWatchlist(wl.id)}>
                              Remove from Watchlist
                            </button>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* 6. SYSTEM AUDIT LOGS */}
        {currentPath === '/logs' && (
          <div className="tab-pane">
            <div className="panel">
              <div className="panel-header">
                <h5>Server Operations Audit Logs</h5>
              </div>
              <div className="log-panel-stream">
                {auditLogs.map(l => (
                  <div className="log-stream-row" key={l.id}>
                    <span className="timestamp">[{new Date(l.timestamp).toLocaleString()}]</span>
                    <span className="user">{l.user}</span>
                    <span className="action">{l.action}</span>
                    <span className="details">{l.details}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {currentPath === '/attendance' && (
          <div className="tab-pane">
            {/* Stats Summary Cards Grid */}
            <div className="stats-card-grid">
              <div className="stat-premium-card">
                <div className="stat-icon-wrapper" style={{ backgroundColor: 'rgba(37,99,235,0.1)', color: '#2563eb' }}>
                  <Users size={20} />
                </div>
                <div className="stat-details">
                  <h3>{attendanceReport.filter(a => !a.checkOut).length}</h3>
                  <p>Active Staff On-Duty</p>
                </div>
              </div>
              <div className="stat-premium-card">
                <div className="stat-icon-wrapper" style={{ backgroundColor: 'rgba(16,185,129,0.1)', color: '#10b981' }}>
                  <Clock size={20} />
                </div>
                <div className="stat-details">
                  <h3>{attendanceReport.filter(a => { 
                    const d = new Date(a.checkIn); 
                    const today = new Date(); 
                    return d.getDate() === today.getDate() && d.getMonth() === today.getMonth() && d.getFullYear() === today.getFullYear(); 
                  }).length}</h3>
                  <p>Check-ins Recorded Today</p>
                </div>
              </div>
              <div className="stat-premium-card">
                <div className="stat-icon-wrapper" style={{ backgroundColor: 'rgba(245,158,11,0.1)', color: '#f59e0b' }}>
                  <ShieldCheck size={20} />
                </div>
                <div className="stat-details">
                  <h3>{shiftReport.filter(s => !s.checkOut).length}</h3>
                  <p>Active Guards On Shift</p>
                </div>
              </div>
              <div className="stat-premium-card">
                <div className="stat-icon-wrapper" style={{ backgroundColor: 'rgba(220,38,38,0.1)', color: '#dc2626' }}>
                  <Plus size={20} />
                </div>
                <div className="stat-details">
                  <h3>{pendingGatePasses.length}</h3>
                  <p>Pending Gate Passes</p>
                </div>
              </div>
            </div>

            {/* 1. Interactive Density Calendar */}
            {renderAttendanceCalendar()}

            {/* 2. Filter System */}
            <div className="panel" style={{ marginBottom: 24, padding: 16 }}>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center' }}>
                <div style={{ flex: 1, minWidth: '200px' }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-mute)', marginBottom: 6 }}>Search Employee / Guard Name</label>
                  <input 
                    type="text" 
                    placeholder="Search by name..."
                    value={attSearchQuery}
                    onChange={(e) => setAttSearchQuery(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid var(--border-color)', borderRadius: '6px', fontSize: '13px' }}
                  />
                </div>
                <div style={{ width: '150px' }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-mute)', marginBottom: 6 }}>Role Filter</label>
                  <select 
                    value={attRoleFilter}
                    onChange={(e) => setAttRoleFilter(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid var(--border-color)', borderRadius: '6px', fontSize: '13px' }}
                  >
                    <option value="All">All Roles</option>
                    <option value="Staff">Staff</option>
                    <option value="SecurityGuard">Security Guard</option>
                    <option value="Admin">Admin</option>
                  </select>
                </div>
                <div style={{ width: '180px' }}>
                  <label style={{ display: 'block', fontSize: '12px', fontWeight: 'bold', color: 'var(--text-mute)', marginBottom: 6 }}>Date Filter</label>
                  <input 
                    type="date" 
                    value={attDateFilter}
                    onChange={(e) => setAttDateFilter(e.target.value)}
                    style={{ width: '100%', padding: '8px 12px', border: '1px solid var(--border-color)', borderRadius: '6px', fontSize: '13px' }}
                  />
                </div>
                <div style={{ alignSelf: 'flex-end' }}>
                  {(attSearchQuery || attRoleFilter !== 'All' || attDateFilter) && (
                    <button 
                      className="btn btn-outline" 
                      onClick={() => {
                        setAttSearchQuery('');
                        setAttRoleFilter('All');
                        setAttDateFilter('');
                        setSelectedCalendarDate(null);
                      }}
                      style={{ height: '38px', fontSize: '13px', borderRadius: '6px' }}
                    >
                      Reset Filters
                    </button>
                  )}
                </div>
              </div>
            </div>

            {/* 3. Daily Attendance Table */}
            <div className="panel">
              <div className="panel-header">
                <h5>Staff Daily Attendance Report</h5>
                <span className="badge-clear">{filteredAttendance.length} records found</span>
              </div>
              <div className="table-responsive">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Employee</th>
                      <th>Role</th>
                      <th>Department</th>
                      <th>Check-In Time</th>
                      <th>Check-Out Time</th>
                      <th>Duration</th>
                      <th>Method & Authorization</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredAttendance.length === 0 ? (
                      <tr>
                        <td colSpan="7" style={{ textAlign: 'center', padding: '24px', color: 'var(--text-mute)' }}>No attendance logs found matching filters.</td>
                      </tr>
                    ) : (
                      filteredAttendance.map(a => {
                        const checkIn = new Date(a.checkIn);
                        const checkOut = a.checkOut ? new Date(a.checkOut) : null;
                        const duration = checkOut ? `${Math.floor((checkOut - checkIn) / 3600000)}h ${Math.floor(((checkOut - checkIn) % 3600000) / 60000)}m` : 'Active';
                        const userPhoto = a.user?.photoUrl || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80";
                        
                        const renderAuthBadge = (actor) => {
                          if (!actor || actor.toLowerCase().includes('self')) {
                            return <span className="badge-self">Self-Auth</span>;
                          }
                          return <span className="badge-guard">{actor}</span>;
                        };

                        return (
                          <tr key={a.id}>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <img src={userPhoto} alt="profile" style={{ width: '32px', height: '32px', borderRadius: '50%', objectFit: 'cover', border: '1px solid var(--border-color)' }} />
                                <strong>{a.user ? `${a.user.firstName} ${a.user.lastName}` : 'Unknown'}</strong>
                              </div>
                            </td>
                            <td><span className="badge-clear">{a.user?.role}</span></td>
                            <td>{a.user?.department}</td>
                            <td>{checkIn.toLocaleString()}</td>
                            <td>{checkOut ? checkOut.toLocaleString() : <em style={{ color: 'orange', fontWeight: '500' }}>On-Duty</em>}</td>
                            <td>{duration}</td>
                            <td>
                              <div style={{ fontSize: '11px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
                                <span className="badge-ocr" style={{ alignSelf: 'flex-start' }}><CheckCircle size={10} style={{ marginRight: 3 }} /> {a.checkInMethod}</span>
                                <div>In by: {renderAuthBadge(a.checkedInBy)}</div>
                                {checkOut && <div>Out by: {renderAuthBadge(a.checkedOutBy)}</div>}
                              </div>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* 4. Security Guard Shift Logs */}
            <div className="panel" style={{ marginTop: 24 }}>
              <div className="panel-header">
                <h5>Security Guard Shift Logs</h5>
                <span className="badge-clear">{filteredShifts.length} shifts found</span>
              </div>
              <div className="table-responsive">
                <table className="table">
                  <thead>
                    <tr>
                      <th>Guard Name</th>
                      <th>Shift Start</th>
                      <th>Shift End</th>
                      <th>Hours Active</th>
                      <th>Terminal IP</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredShifts.length === 0 ? (
                      <tr>
                        <td colSpan="5" style={{ textAlign: 'center', padding: '24px', color: 'var(--text-mute)' }}>No guard shifts found.</td>
                      </tr>
                    ) : (
                      filteredShifts.map(s => {
                        const checkIn = new Date(s.checkIn);
                        const checkOut = s.checkOut ? new Date(s.checkOut) : null;
                        const duration = checkOut ? `${Math.floor((checkOut - checkIn) / 3600000)}h ${Math.floor(((checkOut - checkIn) % 3600000) / 60000)}m` : 'On-Shift';
                        const guardPhoto = s.user?.photoUrl || "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80";
                        return (
                          <tr key={s.id}>
                            <td>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <img src={guardPhoto} alt="profile" style={{ width: '32px', height: '32px', borderRadius: '50%', objectFit: 'cover', border: '1px solid var(--border-color)' }} />
                                <strong>{s.user ? `${s.user.firstName} ${s.user.lastName}` : 'Unknown'}</strong>
                              </div>
                            </td>
                            <td>{checkIn.toLocaleString()}</td>
                            <td>{checkOut ? checkOut.toLocaleString() : <em style={{ color: 'green', fontWeight: 'bold' }}>Active Shift</em>}</td>
                            <td>{duration}</td>
                            <td>{s.ipAddress}</td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* 8. GATE PASS APPROVALS */}
        {currentPath === '/gatepasses' && (
          <div className="tab-pane">
            <div className="panel">
              <div className="panel-header">
                <h5>Pending Early Leaving Requests</h5>
              </div>
              <div className="table-responsive">
                {pendingGatePasses.length === 0 ? (
                  <div className="premium-empty-state">
                    <h5>No Pending Request Logs</h5>
                    <p>When staff submit early checkout requests, they will show up here for authorization.</p>
                  </div>
                ) : (
                  <table className="table">
                    <thead>
                      <tr>
                        <th>Employee</th>
                        <th>Department</th>
                        <th>Reason for Early Leave</th>
                        <th>Request Time</th>
                        <th>Temporary PassCode</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {pendingGatePasses.map(p => (
                        <tr key={p.id}>
                          <td><strong>{p.user ? `${p.user.firstName} ${p.user.lastName}` : 'Unknown'}</strong></td>
                          <td>{p.user?.department}</td>
                          <td><em>"{p.reason}"</em></td>
                          <td>{new Date(p.requestTime).toLocaleString()}</td>
                          <td><span className="badge-manual">{p.passCode}</span></td>
                          <td>
                            <button className="btn btn-sm" style={{ backgroundColor: '#00875a', color: 'white', marginRight: 8, border: 'none', borderRadius: 4, padding: '6px 12px', cursor: 'pointer' }} onClick={() => handleProcessGatePass(p.id, true)}>Approve</button>
                            <button className="btn btn-sm" style={{ backgroundColor: '#de350b', color: 'white', border: 'none', borderRadius: 4, padding: '6px 12px', cursor: 'pointer' }} onClick={() => handleProcessGatePass(p.id, false)}>Reject</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        )}

        </div> {/* End content-body */}

        {/* GLOBAL FOOTER */}
        <footer className="admin-footer">
          <div>&copy; 2026 Institute of Directors. All rights reserved.</div>
          <div className="footer-links">
            <a href="#">Privacy Policy</a>
            <a href="#">Security Terms</a>
            <a href="#">System Help</a>
          </div>
        </footer>

      </main>

      {/* MODAL: ADD EMPLOYEE DRAWER */}
      {showAddEmp && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>Create Staff Employee Account</h3>
              <button onClick={() => setShowAddEmp(false)} className="btn-close"><X /></button>
            </div>
            <form onSubmit={handleAddEmployee}>
              <div className="form-group">
                <label>First Name</label>
                <input 
                  type="text" 
                  required 
                  value={newEmp.firstName} 
                  onChange={e => setNewEmp({...newEmp, firstName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Last Name</label>
                <input 
                  type="text" 
                  required 
                  value={newEmp.lastName} 
                  onChange={e => setNewEmp({...newEmp, lastName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Email Address</label>
                <input 
                  type="email" 
                  required 
                  value={newEmp.email} 
                  onChange={e => setNewEmp({...newEmp, email: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Mobile Number</label>
                <input 
                  type="text" 
                  required 
                  value={newEmp.phone} 
                  onChange={e => setNewEmp({...newEmp, phone: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Designation</label>
                <input 
                  type="text" 
                  required 
                  value={newEmp.designation} 
                  onChange={e => setNewEmp({...newEmp, designation: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Department</label>
                <select value={newEmp.department} onChange={e => setNewEmp({...newEmp, department: e.target.value})}>
                  <option value="Web & IT">Web & IT</option>
                  <option value="Human Resources">Human Resources</option>
                  <option value="Security Operations">Security Operations</option>
                  <option value="Facilities Management">Facilities Management</option>
                  <option value="Finance & Accounting">Finance & Accounting</option>
                  <option value="Corporate Affairs">Corporate Affairs</option>
                </select>
              </div>
              <div className="form-group">
                <label>Access Role</label>
                <select value={newEmp.role} onChange={e => setNewEmp({...newEmp, role: e.target.value})}>
                  <option value="Staff">Staff</option>
                  <option value="Admin">Admin</option>
                  <option value="SecurityGuard">Security Guard</option>
                </select>
              </div>
              {newEmp.photoUrl && (
                <div className="profile-photo-preview-container">
                  <img src={newEmp.photoUrl} alt="Preview" className="profile-photo-preview" />
                  <button type="button" className="btn-remove-photo" onClick={() => setNewEmp({ ...newEmp, photoUrl: '' })}>Remove Image</button>
                </div>
              )}
              <div className="form-group">
                <label>Profile Photo / Face Recognition Image</label>
                <p style={{ fontSize: '12px', color: 'var(--text-mute)', marginTop: '-4px', marginBottom: '8px' }}>Upload a photo from your device or capture via the Face ID scanner. This image is used for biometric gate recognition.</p>
                <div className="image-action-buttons" style={{ display: 'flex', gap: '8px' }}>
                  <label className="btn btn-outline btn-sm cursor-pointer" style={{ margin: 0 }}>
                    <Upload size={14} /> <span>Upload from Storage</span>
                    <input 
                      type="file" 
                      accept="image/*" 
                      style={{ display: 'none' }} 
                      onChange={(e) => handlePhotoUpload(e, false)} 
                    />
                  </label>
                  <button type="button" className="btn btn-outline btn-sm" onClick={() => startCamera(false)}>
                    <Camera size={14} /> <span>Capture Face ID</span>
                  </button>
                </div>
              </div>
              <button type="submit" className="btn btn-primary w-full mt-4">Confirm Registration</button>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: EDIT EMPLOYEE DRAWER */}
      {editEmp && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>Edit Staff Profile</h3>
              <button onClick={() => setEditEmp(null)} className="btn-close"><X /></button>
            </div>
            <form onSubmit={handleUpdateEmployee}>
              <div className="form-group">
                <label>First Name</label>
                <input 
                  type="text" 
                  required 
                  value={editEmp.firstName} 
                  onChange={e => setEditEmp({...editEmp, firstName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Last Name</label>
                <input 
                  type="text" 
                  required 
                  value={editEmp.lastName} 
                  onChange={e => setEditEmp({...editEmp, lastName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Email Address</label>
                <input 
                  type="email" 
                  required 
                  value={editEmp.email} 
                  onChange={e => setEditEmp({...editEmp, email: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Mobile Number</label>
                <input 
                  type="text" 
                  required 
                  value={editEmp.phone} 
                  onChange={e => setEditEmp({...editEmp, phone: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Designation</label>
                <input 
                  type="text" 
                  required 
                  value={editEmp.designation} 
                  onChange={e => setEditEmp({...editEmp, designation: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Department</label>
                <select value={editEmp.department} onChange={e => setEditEmp({...editEmp, department: e.target.value})}>
                  <option value="Web & IT">Web & IT</option>
                  <option value="Human Resources">Human Resources</option>
                  <option value="Security Operations">Security Operations</option>
                  <option value="Facilities Management">Facilities Management</option>
                  <option value="Finance & Accounting">Finance & Accounting</option>
                  <option value="Corporate Affairs">Corporate Affairs</option>
                </select>
              </div>
              <div className="form-group">
                <label>Access Role</label>
                <select value={editEmp.role} onChange={e => setEditEmp({...editEmp, role: e.target.value})}>
                  <option value="Staff">Staff</option>
                  <option value="Admin">Admin</option>
                  <option value="SecurityGuard">Security Guard</option>
                </select>
              </div>
              {editEmp.photoUrl && (
                <div className="profile-photo-preview-container">
                  <img src={editEmp.photoUrl} alt="Preview" className="profile-photo-preview" />
                  <button type="button" className="btn-remove-photo" onClick={() => setEditEmp({ ...editEmp, photoUrl: '' })}>Remove Image</button>
                </div>
              )}
              <div className="form-group">
                <label>Profile Photo / Face Recognition Image</label>
                <p style={{ fontSize: '12px', color: 'var(--text-mute)', marginTop: '-4px', marginBottom: '8px' }}>Upload a photo from your device or capture via the Face ID scanner. This image is used for biometric gate recognition.</p>
                <div className="image-action-buttons" style={{ display: 'flex', gap: '8px' }}>
                  <label className="btn btn-outline btn-sm cursor-pointer" style={{ margin: 0 }}>
                    <Upload size={14} /> <span>Upload from Storage</span>
                    <input 
                      type="file" 
                      accept="image/*" 
                      style={{ display: 'none' }} 
                      onChange={(e) => handlePhotoUpload(e, true)} 
                    />
                  </label>
                  <button type="button" className="btn btn-outline btn-sm" onClick={() => startCamera(true)}>
                    <Camera size={14} /> <span>Capture Face ID</span>
                  </button>
                </div>
              </div>
              <button type="submit" className="btn btn-primary w-full mt-4">Save Changes</button>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: BIOMETRIC FACE RECOG PROGRESS */}
      {faceRegisteringEmp && (
        <div className="modal-overlay">
          <div className="modal-content text-center">
            <h3>Biometric Enroll Scan</h3>
            <p className="text-muted">Registering face template database vectors for: {faceRegisteringEmp.firstName}</p>
            <div className="camera-scan-simulator">
              <img src={faceRegisteringEmp.photoUrl} alt="" className="camera-feed-avatar" />
              <div className="scan-line"></div>
            </div>
            <div className="progress-bar-wrapper">
              <div className="progress-bar" style={{ width: `${faceProgress}%` }}></div>
            </div>
            <span>Enrolling Cosine Vectors: {faceProgress}%</span>
          </div>
        </div>
      )}

      {/* MODAL: ADD WATCHLIST */}
      {showAddWatchlist && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h3>Add Visitor to Watchlist</h3>
              <button onClick={() => setShowAddWatchlist(false)} className="btn-close"><X /></button>
            </div>
            <form onSubmit={handleAddWatchlist}>
              <div className="form-group">
                <label>First Name</label>
                <input 
                  type="text" 
                  required 
                  value={newWl.firstName} 
                  onChange={e => setNewWl({...newWl, firstName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Last Name</label>
                <input 
                  type="text" 
                  required 
                  value={newWl.lastName} 
                  onChange={e => setNewWl({...newWl, lastName: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Phone Contact</label>
                <input 
                  type="text" 
                  required 
                  value={newWl.phone} 
                  onChange={e => setNewWl({...newWl, phone: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Email Address</label>
                <input 
                  type="email" 
                  required 
                  value={newWl.email} 
                  onChange={e => setNewWl({...newWl, email: e.target.value})} 
                />
              </div>
              <div className="form-group">
                <label>Reason for Flagging</label>
                <textarea 
                  required 
                  value={newWl.reason} 
                  onChange={e => setNewWl({...newWl, reason: e.target.value})} 
                />
              </div>
              <button type="submit" className="btn btn-primary w-full mt-4">Save Watchlist Entry</button>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: PRINTABLE DYNAMIC SECURITY ID CARD */}
      {showIDCard && (
        <div className="modal-overlay">
          <div className="modal-content no-padding">
            <div className="modal-header pd-4 border-b">
              <h3>Employee Security ID Card Pass</h3>
              <button onClick={() => setShowIDCard(null)} className="btn-close"><X /></button>
            </div>
            <div className="id-card-wrapper-pane">
              <div className="id-card-container printable-pass">
                {/* Front Side */}
                <div className="id-card-front">
                  <div className="header-logo">
                    <div className="logo-text">IOD</div>
                    <div className="title">
                      <h4>INSTITUTE OF DIRECTORS</h4>
                      <span>Building Tomorrow's Boards</span>
                    </div>
                  </div>
                  <div className="profile-badge-sec">
                    <img src={showIDCard.photoUrl} alt="" className="badge-photo" />
                    <div className="name-sec">
                      <h3>{showIDCard.firstName} {showIDCard.lastName}</h3>
                      <p>{showIDCard.designation}</p>
                    </div>
                  </div>
                  <div className="card-footer-sec">
                    <div className="metadata-box">
                      <div><span>EMP ID:</span> <strong>IOD-{showIDCard.id.substring(0,6).toUpperCase()}</strong></div>
                      <div><span>DEPT:</span> <strong>{showIDCard.department}</strong></div>
                    </div>
                    {/* Functional Security QR Code */}
                    <div className="qr-container" style={{background: '#fff', padding: '6px', borderRadius: '8px'}}>
                      <img 
                        src={`https://api.qrserver.com/v1/create-qr-code/?size=80x80&data=${showIDCard.id}&color=000000`} 
                        alt="Security QR Code" 
                        width="60" 
                        height="60"
                        style={{ display: 'block' }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="modal-actions pd-4 border-t flex justify-end">
              <button className="btn btn-outline-primary mr-2" onClick={() => shareLoginQr(showIDCard.id)}>
                <Share2 size={14} />
                <span>WhatsApp Token</span>
              </button>
              <button className="btn btn-secondary mr-2" onClick={() => window.print()}>
                <Printer size={14} />
                <span>Print Pass Card</span>
              </button>
              <button className="btn btn-primary" onClick={() => setShowIDCard(null)}>Done</button>
            </div>
          </div>
        </div>
      )}
      {/* MODAL: WEBCAM FACE CAPTURE OR MOCK SELECTION SIMULATOR */}
      {showCameraModal && (
        <div className="modal-overlay">
          <div className="modal-content text-center select-portrait-modal">
            <div className="modal-header">
              <h3>Face ID Camera Capture</h3>
              <button onClick={stopCamera} className="btn-close"><X /></button>
            </div>
            
            <p className="text-muted mb-4">
              {cameraActive && !cameraError 
                ? "Align your face inside the circle for biometric vector projection." 
                : "Real-time webcam simulation feed. Select a stock portrait to register."}
            </p>

            <div className="camera-feed-container">
              {cameraActive && !cameraError ? (
                <div className="live-camera-feed-wrapper" style={{ position: 'relative', width: '220px', height: '220px', borderRadius: '50%', overflow: 'hidden', margin: '0 auto', border: '4px solid var(--color-primary)' }}>
                  <video ref={videoRef} autoPlay playsInline muted className="live-video-feed" style={{ width: '100%', height: '100%', objectFit: 'cover' }}></video>
                  <div className="camera-overlay-frame" style={{ position: 'absolute', inset: 0, border: '2px dashed rgba(255,255,255,0.4)', borderRadius: '50%' }}></div>
                  <div className="scan-sweep-bar" style={{ position: 'absolute', left: 0, right: 0, height: '4px', background: 'var(--color-primary)', top: '50%', animation: 'scanAnim 2s infinite ease-in-out' }}></div>
                </div>
              ) : (
                <div className="simulated-camera-feed-wrapper" style={{ position: 'relative', width: '220px', height: '220px', borderRadius: '50%', overflow: 'hidden', margin: '0 auto', border: '4px solid var(--color-primary)' }}>
                  <div className="cyber-grid-scan" style={{ width: '100%', height: '100%', position: 'relative' }}>
                    <img src={selectedMockFace} alt="Selected Face Mock" className="mock-feed-image" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    <div className="face-scan-marker-box" style={{ position: 'absolute', inset: '20px', border: '2px dashed rgba(56, 189, 248, 0.6)', borderRadius: '50%' }}></div>
                    <div className="scan-sweep-bar" style={{ position: 'absolute', left: 0, right: 0, height: '4px', background: '#38bdf8', top: '50%', animation: 'scanAnim 2s infinite ease-in-out' }}></div>
                  </div>
                </div>
              )}
              <canvas ref={canvasRef} style={{ display: 'none' }}></canvas>
            </div>

            {/* Hidden fallback/choice section */}
            {(cameraError || !cameraActive) && (
              <div className="mock-face-selector-section mt-4" style={{ backgroundColor: 'var(--bg-hover)', padding: '16px', borderRadius: 'var(--radius-m)', marginTop: '20px' }}>
                <label className="form-label" style={{ display: 'block', marginBottom: '10px', fontSize: '13px', fontWeight: '600' }}>
                  Select Mock Portrait Vector:
                </label>
                <div className="mock-avatar-thumbnails-grid" style={{ display: 'flex', gap: '8px', justifyContent: 'center', flexWrap: 'wrap' }}>
                  {mockFaces.map((f, idx) => (
                    <img 
                      key={idx}
                      src={f.url} 
                      alt={f.name} 
                      title={f.name}
                      className={`mock-thumb-selector ${selectedMockFace === f.url ? 'active' : ''}`}
                      onClick={() => setSelectedMockFace(f.url)}
                      style={{ width: '48px', height: '48px', borderRadius: '50%', objectFit: 'cover', border: selectedMockFace === f.url ? '3px solid var(--color-primary)' : '2px solid transparent', cursor: 'pointer', transition: 'all 0.15s' }}
                    />
                  ))}
                </div>
                <div className="mock-selected-name-badge mt-2" style={{ fontSize: '11px', color: 'var(--text-sub)', marginTop: '8px' }}>
                  <span>Vector Target: <strong>{mockFaces.find(f => f.url === selectedMockFace)?.name}</strong></span>
                </div>
              </div>
            )}

            <div className="modal-actions-box mt-6" style={{ display: 'flex', gap: '10px', justifyContent: 'center', marginTop: '24px' }}>
              <button className="btn btn-secondary" onClick={stopCamera}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={capturePhoto}>
                <Camera size={14} /> <span>{cameraActive && !cameraError ? "Snap Photo" : "Enforce Biometric Mock"}</span>
              </button>
            </div>
          </div>
        </div>
      )}
      {/* MODAL: DUTY DETAILS */}
      {selectedDutyInfo && (
        <div className="modal-overlay" style={{ background: 'rgba(15,23,42,0.4)', backdropFilter: 'blur(4px)' }}>
          <div className="modal-content" style={{ 
            maxWidth: '550px', 
            background: '#ffffff',
            border: '1px solid #e2e8f0',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            borderRadius: '12px',
            overflow: 'hidden',
            padding: 0
          }}>
            {/* Header */}
            <div style={{ 
              padding: '24px', 
              background: '#f8fafc', 
              borderBottom: '1px solid #e2e8f0',
              position: 'relative',
              display: 'flex', alignItems: 'center', gap: '16px'
            }}>
              <button 
                onClick={() => setSelectedDutyInfo(null)} 
                style={{ 
                  position: 'absolute', top: '16px', right: '16px',
                  background: 'transparent', border: 'none', color: '#64748b',
                  cursor: 'pointer', padding: '4px'
                }}
              >
                <X size={20} />
              </button>
              
              <div style={{
                width: '48px', height: '48px', borderRadius: '8px',
                background: '#eff6ff', color: '#2563eb',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '18px', fontWeight: '700', border: '1px solid #bfdbfe'
              }}>
                {selectedDutyInfo.employeeName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase()}
              </div>
              <div>
                <h3 style={{ margin: '0 0 4px 0', fontSize: '18px', fontWeight: '700', color: '#0f172a' }}>
                  {selectedDutyInfo.employeeName}
                </h3>
                <div style={{ fontSize: '12px', color: '#64748b', fontFamily: 'monospace' }}>
                  ID: {selectedDutyInfo.employeeId}
                </div>
              </div>
            </div>

            {/* Body */}
            <div style={{ padding: '24px', background: '#ffffff' }}>
              
              {/* Info Grid */}
              <div style={{ 
                border: '1px solid #e2e8f0', borderRadius: '8px', overflow: 'hidden', marginBottom: '24px'
              }}>
                <div style={{ padding: '12px 16px', borderBottom: '1px solid #e2e8f0', display: 'flex', gap: '12px' }}>
                  <div style={{ flexShrink: 0, color: '#3b82f6', marginTop: '2px' }}><Target size={16} /></div>
                  <div>
                    <div style={{ fontSize: '11px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Purpose</div>
                    <div style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500', marginTop: '2px' }}>{selectedDutyInfo.reason}</div>
                  </div>
                </div>
                <div style={{ padding: '12px 16px', borderBottom: '1px solid #e2e8f0', display: 'flex', gap: '12px', background: '#f8fafc' }}>
                  <div style={{ flexShrink: 0, color: '#3b82f6', marginTop: '2px' }}><MapPin size={16} /></div>
                  <div>
                    <div style={{ fontSize: '11px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Destination</div>
                    <div style={{ fontSize: '14px', color: '#0f172a', fontWeight: '500', marginTop: '2px' }}>{selectedDutyInfo.destination}</div>
                  </div>
                </div>
                <div style={{ padding: '12px 16px', display: 'flex', gap: '32px' }}>
                  <div style={{ display: 'flex', gap: '12px' }}>
                    <div style={{ flexShrink: 0, color: '#3b82f6', marginTop: '2px' }}><Clock size={16} /></div>
                    <div>
                      <div style={{ fontSize: '11px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Out Time</div>
                      <div style={{ fontSize: '14px', color: '#0f172a', fontWeight: '600', marginTop: '2px' }}>
                        {new Date(selectedDutyInfo.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '12px' }}>
                    <div style={{ flexShrink: 0, color: '#3b82f6', marginTop: '2px' }}><Clock size={16} /></div>
                    <div>
                      <div style={{ fontSize: '11px', fontWeight: '600', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Est. Return</div>
                      <div style={{ fontSize: '14px', color: '#0f172a', fontWeight: '600', marginTop: '2px' }}>
                        {new Date(new Date(selectedDutyInfo.startTime).getTime() + 2 * 60 * 60 * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Ping History Table */}
              <h4 style={{ 
                fontSize: '14px', fontWeight: '700', color: '#0f172a', 
                marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px'
              }}>
                <Navigation2 size={16} color="#3b82f6" /> Location Ping History
              </h4>
              
              <div style={{ 
                maxHeight: '240px', overflowY: 'auto',
                border: '1px solid #e2e8f0', borderRadius: '8px'
              }}>
                {(selectedDutyInfo.coordinates || selectedDutyInfo.Coordinates || []).length === 0 ? (
                  <div style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px', background: '#f8fafc' }}>
                    No location pings logged yet.
                  </div>
                ) : (
                  <table style={{ width: '100%', textAlign: 'left', borderCollapse: 'collapse', fontSize: '13px' }}>
                    <thead style={{ position: 'sticky', top: 0, background: '#eff6ff', boxShadow: '0 1px 2px rgba(0,0,0,0.05)' }}>
                      <tr>
                        <th style={{ padding: '10px 16px', color: '#1d4ed8', fontWeight: '600', width: '25%' }}>Time</th>
                        <th style={{ padding: '10px 16px', color: '#1d4ed8', fontWeight: '600', width: '75%' }}>Location / Address</th>
                      </tr>
                    </thead>
                    <tbody>
                      {(selectedDutyInfo.coordinates || selectedDutyInfo.Coordinates || [])
                        .filter(c => (c.lat ?? c.latitude ?? c.Latitude) != null && (c.lng ?? c.longitude ?? c.Longitude) != null)
                        .slice().reverse().map((coord, idx) => {
                        const ts = coord.timestamp || coord.Timestamp || coord.time;
                        return (
                          <tr key={idx} style={{ borderBottom: '1px solid #f1f5f9', background: idx === 0 ? '#f0fdf4' : '#ffffff' }}>
                            <td style={{ padding: '12px 16px', color: '#334155', fontWeight: idx === 0 ? '600' : '400', verticalAlign: 'top' }}>
                              {ts ? new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : '--:--'}
                            </td>
                            <td style={{ padding: '12px 16px', color: '#475569', lineHeight: '1.4' }}>
                              <div style={{ fontSize: '11px', color: idx === 0 ? '#15803d' : '#94a3b8', fontFamily: 'monospace', marginBottom: '2px' }}>
                                {(coord.lat ?? coord.latitude ?? coord.Latitude).toFixed(6)}, {(coord.lng ?? coord.longitude ?? coord.Longitude).toFixed(6)}
                              </div>
                              <CoordinateAddress lat={coord.lat ?? coord.latitude ?? coord.Latitude} lng={coord.lng ?? coord.longitude ?? coord.Longitude} />
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
