// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\mobile_app\lib\screens\guard_dashboard.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import 'face_auth_screen.dart';

class GuardDashboard extends StatefulWidget {
  const GuardDashboard({super.key});

  @override
  State<GuardDashboard> createState() => _GuardDashboardState();
}

class _GuardDashboardState extends State<GuardDashboard> with TickerProviderStateMixin {
  Map<String, dynamic> _user = {};
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _shimmerController;
  final ScrollController _scrollController = ScrollController();

  // Guard specific states
  bool _isShiftActive = false;
  String _shiftCheckInTime = "--:--";
  String _shiftCheckOutTime = "--:--";
  String _guardActiveLogId = "";

  // Guard's own gate pass states
  List<dynamic> _gatePasses = [];
  bool _isLoadingGatePasses = false;
  final TextEditingController _gatePassReasonController = TextEditingController();
  TimeOfDay? _selectedLeaveTime = null;

  // Active visitor list state
  List<dynamic> _activeVisitors = [];
  bool _loadingVisitors = false;

  // Employee list (hosts) state
  List<dynamic> _employees = [];

  // Visitor check-in form states
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _visitorDesignationController = TextEditingController();
  final TextEditingController _visitorCardIdController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController(text: "Business Meeting");
  String? _selectedHostId = null;
  String? _visitorPhotoBase64 = null;
  bool _isCardScanned = false;

  // Staff entry state (when scanned by guard)
  Map<String, dynamic>? _scannedEmployee = null;
  bool _isEmployeeClockedIn = false;
  String? _scannedEmployeeLastCheckIn = null;
  bool _loadingScannedEmployee = false;
  bool _isEmployeeFaceVerified = false;

  // Scanner states
  bool _isScanningCard = false;
  double _scanProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    _gatePassReasonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _visitorDesignationController.dispose();
    _visitorCardIdController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Load guard's profile
      final profile = await ApiService().getProfile();
      if (mounted) setState(() => _user = profile);

      // Check active shift (detect already-punched-in state)
      await _checkGuardActiveShift();

      // Load employees (for visitor host selector)
      final emps = await ApiService().getEmployees();
      if (mounted) setState(() => _employees = emps);

      // Load active visitors
      await _refreshVisitors();

      // Load own gate passes
      await _loadGatePasses();
    } catch (e) {
      debugPrint('[Guard] _loadInitialData error: $e');
      // Fallback: keep minimal data so screen still renders
      if (mounted) setState(() => _user = _user.isEmpty ? {"firstName": "Guard", "id": ""} : _user);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGatePasses() async {
    setState(() => _isLoadingGatePasses = true);
    try {
      final passes = await ApiService().getMyGatePasses();
      if (mounted) setState(() => _gatePasses = passes);
    } catch (e) {
      debugPrint('[Guard] _loadGatePasses error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGatePasses = false);
    }
  }


  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _requestEarlyLeavingGatePass() async {
    final reason = _gatePassReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason for early leave."), backgroundColor: Colors.orange));
      return;
    }
    if (_selectedLeaveTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a leave time."), backgroundColor: Colors.orange));
      return;
    }
    try {
      final leaveTimeStr = "${_selectedLeaveTime!.hour.toString().padLeft(2,'0')}:${_selectedLeaveTime!.minute.toString().padLeft(2,'0')}";
      await ApiService().requestGatePass(reason, leaveTimeStr);
      _gatePassReasonController.clear();
      setState(() => _selectedLeaveTime = null);
      await _loadGatePasses();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gate pass request submitted."), backgroundColor: Color(0xFF10B981)));
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }


  void _showGuardProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleLogout();
              },
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }

  void _showDigitalIDCard() {
    showDialog(
      context: context,
      builder: (ctx) {
        final photoUrl = _user["photoUrl"] ?? "";
        final hasPhoto = photoUrl.isNotEmpty && photoUrl.toString().startsWith("http");
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.grey[950],
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "INSTITUTE OF DIRECTORS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  "SENTRY FORCE IDENTITY",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white10,
                    backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    child: !hasPhoto 
                        ? const Icon(Icons.security, size: 45, color: Colors.white70) 
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${_user["firstName"] ?? ""} ${_user["lastName"] ?? ""}".toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _user["designation"] ?? "Security Guard",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _user["department"] ?? "Security Sentry",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _user["id"] ?? "No ID",
                    version: QrVersions.auto,
                    size: 140.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Emp ID: ${_user["id"] != null ? (_user["id"].toString().length > 8 ? _user["id"].toString().substring(0, 8) : _user["id"].toString()) : "No ID"}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Close", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGatePassQrDialog(String passCode) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Gate Pass QR"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Present this QR to the gate scanner to leave.", textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: passCode,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                passCode,
                style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }


  Future<void> _checkGuardActiveShift() async {
    try {
      // Primary: dedicated active-shift endpoint (fast, unambiguous)
      final shift = await ApiService().getActiveShift();
      debugPrint("[Shift Check] Active-shift response: $shift");
      final bool isActive = shift["isActive"] == true;
      if (isActive) {
        final checkInStr = shift["checkIn"].toString();
        final checkInTimeParsed = DateTime.parse(checkInStr).toLocal();
        if (mounted) setState(() {
          _isShiftActive = true;
          _guardActiveLogId = shift["logId"]?.toString() ?? "";
          _shiftCheckInTime = "${checkInTimeParsed.hour.toString().padLeft(2, '0')}:${checkInTimeParsed.minute.toString().padLeft(2, '0')}";
          _shiftCheckOutTime = "--:--";
        });
      } else {
        if (mounted) setState(() {
          _isShiftActive = false;
          _shiftCheckInTime = "--:--";
          _shiftCheckOutTime = "--:--";
          _guardActiveLogId = "";
        });
      }
    } catch (primaryError) {
      debugPrint("[Shift Check] Primary failed: $primaryError — trying history fallback...");
      // Fallback: parse attendance history
      try {
        final history = await ApiService().getAttendanceHistory();
        debugPrint("[Shift Check] History fallback: ${history.length} records");
        if (history.isNotEmpty) {
          final lastLog = history.first;
          debugPrint("[Shift Check] Last log checkOut: ${lastLog['checkOut']}");
          if (lastLog["checkOut"] == null) {
            final checkInTimeParsed = DateTime.parse(lastLog["checkIn"].toString()).toLocal();
            if (mounted) setState(() {
              _isShiftActive = true;
              _guardActiveLogId = lastLog["id"]?.toString() ?? "";
              _shiftCheckInTime = "${checkInTimeParsed.hour.toString().padLeft(2, '0')}:${checkInTimeParsed.minute.toString().padLeft(2, '0')}";
              _shiftCheckOutTime = "--:--";
            });
          } else {
            if (mounted) setState(() {
              _isShiftActive = false;
              _shiftCheckInTime = "--:--";
              _shiftCheckOutTime = "--:--";
              _guardActiveLogId = "";
            });
          }
        }
      } catch (fallbackError) {
        debugPrint("[Shift Check] Both methods failed: $fallbackError");
      }
    }
  }


  Future<void> _refreshVisitors() async {
    setState(() {
      _loadingVisitors = true;
    });
    try {
      final active = await ApiService().getActiveVisitors();
      setState(() {
        _activeVisitors = active;
      });
    } catch (e) {
      debugPrint("Error refreshing visitors: $e");
    } finally {
      setState(() {
        _loadingVisitors = false;
      });
    }
  }

  // Guard's own shift Punch In
  void _triggerGuardShiftPunchIn() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceAuthScreen(
          role: 'SecurityGuard',
          returnToCallerOnSuccess: true,
        ),
      ),
    );

    if (result == true) {
      try {
        final res = await ApiService().checkIn("Face", "Gate Guard Terminal");
        final checkInTimeParsed = DateTime.parse(res["checkIn"]).toLocal();
        setState(() {
          _isShiftActive = true;
          _shiftCheckInTime = "${checkInTimeParsed.hour.toString().padLeft(2, '0')}:${checkInTimeParsed.minute.toString().padLeft(2, '0')}";
          _shiftCheckOutTime = "--:--";
          _guardActiveLogId = res["logId"] ?? "";
        });
        await _checkGuardActiveShift();

        await _requestGuardTrackingAccess();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Guard Shift Punch-In Registered. GPS Active."), backgroundColor: Colors.green),
        );
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  // Guard's own shift Punch Out
  void _triggerGuardShiftPunchOut() async {
    try {
      final res = await ApiService().checkOut();
      final checkOutTimeParsed = DateTime.parse(res["checkOut"]).toLocal();
      setState(() {
        _isShiftActive = false;
        _shiftCheckOutTime = "${checkOutTimeParsed.hour.toString().padLeft(2, '0')}:${checkOutTimeParsed.minute.toString().padLeft(2, '0')}";
        _guardActiveLogId = "";
      });
      await _checkGuardActiveShift();

      FlutterBackgroundService().invoke('stopService');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guard Shift Punch-Out Registered successfully."), backgroundColor: Colors.blue),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<bool> _requestGuardTrackingAccess() async {
    final notificationStatus = await Permission.notification.request();
    final locationStatus = await Permission.locationAlways.request();

    final hasAccess = notificationStatus.isGranted && locationStatus.isGranted;
    if (hasAccess) {
      FlutterBackgroundService().invoke('setAsForeground');
      FlutterBackgroundService().startService();
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Allow notifications and always-on location for background tracking."),
        ),
      );
    }

    if (notificationStatus.isPermanentlyDenied || locationStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    return false;
  }

  // Open QR Scanner Sheet
  Future<String?> _openQrScanner() async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              AppBar(
                title: const Text("Scan QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (capture.barcodes.isNotEmpty) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null) {
                        Navigator.pop(context, code);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Guard Scans Employee ID QR Code
  void _scanEmployeeIdQr() async {
    final scannedCode = await _openQrScanner();
    if (scannedCode == null || scannedCode.isEmpty) return;

    setState(() => _loadingScannedEmployee = true);
    try {
      final res = await ApiService().getEmployeeAttendanceState(scannedCode);
      setState(() {
        _scannedEmployee = res["employee"];
        _isEmployeeClockedIn = res["isClockedIn"];
        _scannedEmployeeLastCheckIn = res["checkInTime"] != null
            ? DateTime.parse(res["checkInTime"]).toLocal().toString().substring(11, 16)
            : null;
        _loadingScannedEmployee = false;
        _isEmployeeFaceVerified = false; // Reset Face ID verification for the new scan
      });
    } catch (e) {
      setState(() => _loadingScannedEmployee = false);
      _showErrorDialog("Failed to load employee details: $e");
    }
  }

  // Guard Scans Employee Face ID
  void _scanEmployeeFace() async {
    if (_scannedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please scan Employee ID QR code first!"), backgroundColor: Colors.red),
      );
      return;
    }

    // Navigates to face auth screen with back camera enabled so guard can scan the staff member's face.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceAuthScreen(
          role: 'Staff',
          returnToCallerOnSuccess: true,
          useBackCamera: true,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _isEmployeeFaceVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face matches successfully! Biometrics Verified."), backgroundColor: Colors.green),
      );
    }
  }

  // Guard Registers Attendance In or Out
  void _submitStaffAttendance(String direction) async {
    if (_scannedEmployee == null) return;

    if (!_isEmployeeFaceVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric Face ID verification is required before checking in!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loadingScannedEmployee = true);
    try {
      await ApiService().registerStaffAttendance(
        _scannedEmployee!["id"],
        "QR + Face ID Scan (Verified)",
        direction,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Employee ${direction == 'In' ? 'Clocked In' : 'Clocked Out'} successfully!"), backgroundColor: Colors.green),
      );
      setState(() {
        _scannedEmployee = null;
        _isEmployeeFaceVerified = false;
        _loadingScannedEmployee = false;
      });
    } catch (e) {
      setState(() => _loadingScannedEmployee = false);
      _showErrorDialog(e.toString());
    }
  }


  // Guard scans early leaving Gate Pass QR
  void _scanEarlyLeavingGatePass() async {
    final scannedCode = await _openQrScanner();
    if (scannedCode == null || scannedCode.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService().scanGatePass(scannedCode);
      final employee = res["employee"];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Gate Pass Redeemed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          content: Text("Employee ${employee?["firstName"]} ${employee?["lastName"]} is cleared to leave. Logged early clock-out."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            )
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog("Gate Pass Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Capture Visitor Face Photo
  void _captureVisitorFacePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    final base64String = "data:image/jpeg;base64," + base64.encode(bytes);
    
    setState(() {
      _visitorPhotoBase64 = base64String;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Visitor Face ID Captured successfully."), backgroundColor: Colors.green),
    );
  }

  // OCR Business Card Scan
  void _triggerCardOcrScan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isScanningCard = true;
      _scanProgress = 0.1;
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      setState(() => _scanProgress = 0.4);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() => _scanProgress = 0.8);
      
      String text = recognizedText.text;
      
      // Parse details
      final emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
      final emailMatch = emailRegex.firstMatch(text);
      if (emailMatch != null) {
        _emailController.text = emailMatch.group(0) ?? "";
      }

      final phoneRegex = RegExp(r'(?:\+?\d{1,3}[- ]?)?\d{10}');
      final phoneMatch = phoneRegex.firstMatch(text);
      if (phoneMatch != null) {
        _phoneController.text = phoneMatch.group(0) ?? "";
      }

      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty) {
        String parsedName = "";
        String parsedDesignation = "";
        String parsedCompany = "";
        
        for (var line in lines) {
          if (line.toLowerCase().contains("swami") || line.toLowerCase().contains("ravi") || line.toLowerCase().contains("kumar") || line.toLowerCase().contains("sharma") || line.toLowerCase().contains("singh")) {
            parsedName = line;
          }
          if (line.toLowerCase().contains("manager") || line.toLowerCase().contains("intern") || line.toLowerCase().contains("director") || line.toLowerCase().contains("lead") || line.toLowerCase().contains("supervisor") || line.toLowerCase().contains("specialist") || line.toLowerCase().contains("developer") || line.toLowerCase().contains("secretary")) {
            parsedDesignation = line;
          }
          if (line.toLowerCase().contains("institute") || line.toLowerCase().contains("director") || line.toLowerCase().contains("company") || line.toLowerCase().contains("ltd") || line.toLowerCase().contains("pvt")) {
            parsedCompany = line;
          }
        }

        if (parsedName.isEmpty && lines.isNotEmpty) {
          parsedName = lines[0];
        }
        
        if (parsedName.isNotEmpty) {
          final parts = parsedName.split(' ');
          if (parts.length > 1) {
            _firstNameController.text = parts[0];
            _lastNameController.text = parts.sublist(1).join(' ');
          } else {
            _firstNameController.text = parsedName;
          }
        }
        
        if (parsedDesignation.isNotEmpty) {
          _visitorDesignationController.text = parsedDesignation;
        }

        if (parsedCompany.isNotEmpty) {
          _companyController.text = parsedCompany;
        }
      }

      textRecognizer.close();
      setState(() {
        _isCardScanned = true; // Mark as Verified ID Card
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OCR Scan Success: Card details loaded."), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint("OCR ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to read card: $e")),
      );
    } finally {
      setState(() {
        _isScanningCard = false;
        _scanProgress = 1.0;
      });
    }
  }

  // Submit Visitor Check-In
  void _submitVisitorCheckIn() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _companyController.text.isEmpty ||
        _selectedHostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details and select a host employee.")),
      );
      return;
    }

    if (_visitorPhotoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please capture visitor Face ID photo to verify them.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final details = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "company": _companyController.text.trim(),
        "designation": _visitorDesignationController.text.trim(),
        "visitorCardId": _visitorCardIdController.text.trim(),
        "hostEmployeeId": _selectedHostId,
        "purpose": _purposeController.text.trim(),
        "cardScanned": _isCardScanned,
        "photoUrl": _visitorPhotoBase64
      };

      final res = await ApiService().checkInVisitor(details);
      
      // Clear forms
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _companyController.clear();
      _visitorDesignationController.clear();
      _visitorCardIdController.clear();
      _selectedHostId = null;
      _visitorPhotoBase64 = null;
      _isCardScanned = false;

      await _refreshVisitors();

      final bool watchlistTriggered = res["watchlistTriggered"] ?? false;
      final pass = res["pass"] ?? res;

      _showPassDialog(pass, watchlistTriggered);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkoutVisitor(String passId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ApiService().checkoutVisitor(passId);
      await _refreshVisitors();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visitor Checked Out successfully."), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _showPassDialog(Map<String, dynamic> pass, bool isWatchlist) {
    showDialog(
      context: context,
      barrierDismissible: !isWatchlist,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isWatchlist ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
              color: isWatchlist ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              isWatchlist ? "SECURITY ALERT" : "VISITOR PASS ISSUED",
              style: TextStyle(
                color: isWatchlist ? Colors.red : Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWatchlist) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "WATCHLIST THREAT DETECTED: This visitor matches a watchlist target. Alert dispatched to Admin.",
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(pass["photoUrl"] ?? ""),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${pass["firstName"]} ${pass["lastName"]}".toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      pass["company"],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24),
                    _buildPassDetailRow("Host Employee", pass["hostName"]),
                    _buildPassDetailRow("Department", pass["hostDepartment"]),
                    _buildPassDetailRow("Purpose", pass["purpose"]),
                    _buildPassDetailRow("Verified ID", pass["cardScanned"] == true ? "YES (Card Scanned)" : "NO (Manual Entry)"),
                    _buildPassDetailRow("Check-In Time", pass["checkInTime"] != null ? DateTime.parse(pass["checkInTime"]).toLocal().toString().substring(11, 16) : "--:--"),
                  ],
                ),
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Print & Done"),
          )
        ],
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  ImageProvider? _getSafeImage(String? url) {
    if (url == null || url.isEmpty || url == "null" || url == "string") return null;
    try {
      if (url.startsWith("http")) {
        return NetworkImage(url);
      } else {
        final baseUrl = ApiService().baseUrl.replaceAll("/api/v1", "");
        final fullUrl = url.startsWith("/") ? "$baseUrl$url" : "$baseUrl/$url";
        return NetworkImage(fullUrl);
      }
    } catch (_) {
      return null;
    }
  }

  Widget _buildSafeAvatar(String? url, {double radius = 20}) {
    final isValidUrl = url != null && url.isNotEmpty && url != "null" && url != "string" && url.length > 5;
    if (!isValidUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
        child: Icon(Icons.person, size: radius, color: const Color(0xFF6366F1)),
      );
    }
    final fullUrl = url!.startsWith("http") ? url : "${ApiService().baseUrl.replaceAll("/api/v1", "")}${url.startsWith("/") ? url : "/$url"}";
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.15),
      child: ClipOval(
        child: Image.network(
          fullUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: radius, color: const Color(0xFF6366F1)),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : SizedBox(
                  width: radius * 2, height: radius * 2,
                  child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF6366F1)),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shimmerBase = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final shimmerHigh = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar skeleton
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: card,
              child: Row(
                children: [
                  _shimmerBox(32, 32, radius: 8, base: shimmerBase, high: shimmerHigh),
                  const SizedBox(width: 12),
                  _shimmerBox(160, 18, radius: 6, base: shimmerBase, high: shimmerHigh),
                  const Spacer(),
                  _shimmerBox(36, 36, radius: 18, base: shimmerBase, high: shimmerHigh),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _shimmerBox(70, 70, radius: 35, base: shimmerBase, high: shimmerHigh),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _shimmerBox(140, 18, radius: 6, base: shimmerBase, high: shimmerHigh),
                              const SizedBox(height: 10),
                              _shimmerBox(100, 13, radius: 6, base: shimmerBase, high: shimmerHigh),
                              const SizedBox(height: 10),
                              _shimmerBox(80, 30, radius: 15, base: shimmerBase, high: shimmerHigh),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _shimmerBox(120, 14, radius: 4, base: shimmerBase, high: shimmerHigh),
                    const SizedBox(height: 12),
                    _shimmerBox(double.infinity, 100, radius: 16, base: shimmerBase, high: shimmerHigh),
                    const SizedBox(height: 16),
                    _shimmerBox(double.infinity, 100, radius: 16, base: shimmerBase, high: shimmerHigh),
                    const SizedBox(height: 16),
                    _shimmerBox(double.infinity, 70, radius: 16, base: shimmerBase, high: shimmerHigh),
                  ],
                ),
              ),
            ),
            // Bottom nav skeleton
            Container(
              height: 64,
              color: card,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5, (_) => _shimmerBox(40, 40, radius: 8, base: shimmerBase, high: shimmerHigh)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 8, Color? base, Color? high}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
        return Container(
          width: width == double.infinity ? null : width,
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(
              base ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
              high ?? (isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF0F0F0)),
              _shimmerController.value,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }


  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingSkeleton();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titles = ["On Duty", "Staff Entry", "Visitors", "Gate Passes", "My ID"];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glowing orb — top right
            Positioned(
              top: -60, right: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(isDark ? 0.10 : 0.07),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.12), blurRadius: 90)],
                ),
              ),
            ),
            // Decorative glowing orb — bottom left
            Positioned(
              bottom: 80, left: -90,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(isDark ? 0.07 : 0.05),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.10), blurRadius: 100)],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Top App Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        // Shield Logo
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Center(child: Icon(Icons.shield, color: Colors.white, size: 22)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[_tabController.index],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                            ),
                            Text("Security Guard Portal", style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          ],
                        ),
                        const Spacer(),
                        // Shift status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isShiftActive ? const Color(0xFF10B981).withOpacity(0.15) : Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _isShiftActive ? const Color(0xFF10B981).withOpacity(0.4) : Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  color: _isShiftActive ? const Color(0xFF10B981) : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isShiftActive ? "On Shift" : "Off Shift",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isShiftActive ? const Color(0xFF10B981) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _showDigitalIDCard,
                          child: _buildSafeAvatar(_user["photoUrl"], radius: 20),
                        ),
                      ],
                    ),
                  ),

                  // ── Tab Pages ──
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMyShiftPage(isDark),
                        _buildStaffEntryPage(isDark),
                        _buildVisitorsPage(isDark),
                        _buildGatePassPage(isDark),
                        _buildMyIdPage(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Premium Bottom Nav ──
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.92) : Colors.white.withOpacity(0.92),
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.07) : Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.shield_outlined, Icons.shield, "On Duty", isDark),
                    _navItem(1, Icons.badge_outlined, Icons.badge, "Staff", isDark),
                    _navItem(2, Icons.people_outline, Icons.people, "Visitors", isDark),
                    _navItem(3, Icons.directions_walk_outlined, Icons.directions_walk, "Passes", isDark),
                    _navItem(4, Icons.qr_code_2_outlined, Icons.qr_code_2, "My ID", isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, bool isDark) {
    final isSelected = _tabController.index == index;
    final color = const Color(0xFF10B981);
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? color : (isDark ? Colors.grey[500] : Colors.grey[600]),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB PAGES ───────────────────────────────────────────────────────────────

  Widget _buildMyShiftPage(bool isDark) {
    final fn = (_user['firstName'] ?? '').toString().replaceAll('null', '').trim();
    final ln = (_user['lastName'] ?? '').toString().replaceAll('null', '').trim();
    final fullName = "$fn $ln".trim();
    final textColor = isDark ? Colors.white : Colors.black87;
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Guard Profile Summary
          _glassCard(
            isDark: isDark,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 12)],
                  ),
                  padding: const EdgeInsets.all(2),
                  child: _buildSafeAvatar(_user['photoUrl']?.toString(), radius: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'Security Guard' : fullName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (_user['designation']?.toString().replaceAll('null','').trim().isNotEmpty == true)
                            ? _user['designation'].toString()
                            : 'Security Guard',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (_user['department']?.toString().replaceAll('null','').trim().isNotEmpty == true)
                            ? _user['department'].toString()
                            : 'Security Sentry',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isShiftActive ? const Color(0xFF10B981).withOpacity(0.12) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(color: _isShiftActive ? const Color(0xFF10B981) : Colors.grey, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(_isShiftActive ? 'Active' : 'Off Duty',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isShiftActive ? const Color(0xFF10B981) : Colors.grey)),
                        ],
                      ),
                    ),
                    if (_user['email'] != null && _user['email'].toString() != 'null') ...[                      const SizedBox(height: 6),
                      Text(_user['email'].toString(), style: const TextStyle(color: Colors.grey, fontSize: 10), overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shift Hero Card
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isShiftActive
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (_isShiftActive ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.35),
                  blurRadius: 30, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isShiftActive ? Icons.shield : Icons.shield_outlined,
                    color: Colors.white, size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isShiftActive ? "Shift Active" : "Shift Not Started",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isShiftActive ? "GPS tracking is running in background." : "Punch in to begin your security shift.",
                  style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _timeCol("SHIFT IN", _shiftCheckInTime),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _timeCol("SHIFT OUT", _shiftCheckOutTime),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Punch In / Out Card
          _glassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Shift Control", Icons.login),
                const SizedBox(height: 8),
                Text(
                  _isShiftActive
                      ? "You are currently on shift. Tap to end your shift."
                      : "Use biometric face scan to punch in for your security shift.",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isShiftActive ? _triggerGuardShiftPunchOut : _triggerGuardShiftPunchIn,
                    icon: Icon(_isShiftActive ? Icons.logout : Icons.face_retouching_natural),
                    label: Text(
                      _isShiftActive ? "Punch Out (End Shift)" : "Punch In (Start Shift)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isShiftActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _glassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Quick Actions", Icons.bolt),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _actionTile(
                        icon: Icons.qr_code_scanner,
                        label: "Scan Gate Pass",
                        color: const Color(0xFF6366F1),
                        onTap: _scanEarlyLeavingGatePass,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.qr_code_2,
                        label: "My ID Card",
                        color: const Color(0xFF0EA5E9),
                        onTap: _showDigitalIDCard,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.logout,
                        label: "Sign Out",
                        color: const Color(0xFFEF4444),
                        onTap: _handleLogout,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffEntryPage(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Scan employee QR
          _glassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Scan Employee QR", Icons.qr_code_scanner),
                const SizedBox(height: 8),
                Text(
                  "Scan an employee's ID QR code to load their attendance state, then verify with Face ID.",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _scanEmployeeIdQr,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Scan Employee ID QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scanned Employee Card
          if (_loadingScannedEmployee)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF10B981))))
          else if (_scannedEmployee != null) ...[
            _glassCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Scanned Employee", Icons.person_search),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSafeAvatar(_scannedEmployee!["photoUrl"]?.toString(), radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_scannedEmployee!["firstName"] ?? ""} ${_scannedEmployee!["lastName"] ?? ""}",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _scannedEmployee!["designation"]?.toString() ?? "Staff Employee",
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            _statusBadge(_isEmployeeClockedIn ? "Clocked In" : "Clocked Out", _isEmployeeClockedIn ? const Color(0xFF10B981) : Colors.orange),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_scannedEmployeeLastCheckIn != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text("Last Check-In: ${_scannedEmployeeLastCheckIn!}", style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Face Verify
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _scanEmployeeFace,
                      icon: Icon(_isEmployeeFaceVerified ? Icons.verified_user : Icons.face_retouching_natural, color: _isEmployeeFaceVerified ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                      label: Text(
                        _isEmployeeFaceVerified ? "Face Verified ✓" : "Verify Face ID",
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isEmployeeFaceVerified ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _isEmployeeFaceVerified ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Clock In / Out Buttons
                  Row(
                    children: [
                      if (!_isEmployeeClockedIn)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _submitStaffAttendance("In"),
                              icon: const Icon(Icons.login),
                              label: const Text("Clock In", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      if (_isEmployeeClockedIn) ...[
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _submitStaffAttendance("Out"),
                              icon: const Icon(Icons.logout),
                              label: const Text("Clock Out", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ] else
            _emptyState(isDark, icon: Icons.badge_outlined, message: "Scan an employee QR code above to load their details."),
        ],
      ),
    );
  }

  Widget _buildVisitorsPage(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshVisitors,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Check-In Form
          _glassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Visitor Check-In", Icons.person_add_outlined),
                const SizedBox(height: 8),
                Text("Fill visitor details and capture Face ID photo.", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 18),

                // OCR Scan Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _triggerCardOcrScan,
                    icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFF6366F1)),
                    label: Text(
                      _isCardScanned ? "Card Scanned ✓" : "Scan Business Card (OCR)",
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isCardScanned ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_isScanningCard) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: _scanProgress, color: const Color(0xFF6366F1), backgroundColor: Colors.grey.shade200),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _inputField(controller: _firstNameController, label: "First Name", icon: Icons.person_outline, isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _inputField(controller: _lastNameController, label: "Last Name", icon: Icons.person_outline, isDark: isDark)),
                  ],
                ),
                const SizedBox(height: 10),
                _inputField(controller: _emailController, label: "Email", icon: Icons.email_outlined, isDark: isDark),
                const SizedBox(height: 10),
                _inputField(controller: _phoneController, label: "Phone", icon: Icons.phone_outlined, isDark: isDark),
                const SizedBox(height: 10),
                _inputField(controller: _companyController, label: "Company", icon: Icons.business_outlined, isDark: isDark),
                const SizedBox(height: 10),
                _inputField(controller: _visitorDesignationController, label: "Designation", icon: Icons.work_outline, isDark: isDark),
                const SizedBox(height: 10),
                _inputField(controller: _purposeController, label: "Purpose of Visit", icon: Icons.notes, isDark: isDark),
                const SizedBox(height: 10),

                // Host selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select Host Employee"),
                      value: _selectedHostId,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: _employees.map<DropdownMenuItem<String>>((emp) {
                        return DropdownMenuItem<String>(
                          value: emp["id"].toString(),
                          child: Text("${emp["firstName"]} ${emp["lastName"]}", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedHostId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Face Photo
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _captureVisitorFacePhoto,
                          icon: Icon(_visitorPhotoBase64 != null ? Icons.check_circle_outline : Icons.camera_alt_outlined, color: _visitorPhotoBase64 != null ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                          label: Text(_visitorPhotoBase64 != null ? "Photo Captured ✓" : "Capture Face Photo", style: TextStyle(color: _visitorPhotoBase64 != null ? const Color(0xFF10B981) : const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _visitorPhotoBase64 != null ? const Color(0xFF10B981) : const Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _submitVisitorCheckIn,
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text("Register Visitor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Visitors List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ACTIVE VISITORS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
              GestureDetector(onTap: _refreshVisitors, child: const Icon(Icons.refresh, size: 20, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 12),
          _loadingVisitors
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF10B981))))
              : _activeVisitors.isEmpty
                  ? _emptyState(isDark, icon: Icons.people_outline, message: "No active visitors on premises.")
                  : Column(children: _activeVisitors.map((v) => _buildVisitorCard(v, isDark)).toList()),
        ],
      ),
    );
  }

  Widget _buildGatePassPage(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Scan pass
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 25, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text("SCAN GATE PASS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Scan employee's gate pass QR code to authorize early exit.", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _scanEarlyLeavingGatePass,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text("Scan QR Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6366F1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // My Own Gate Pass Request
          _glassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("My Gate Pass Request", Icons.badge_outlined),
                const SizedBox(height: 8),
                Text("Request early leave authorization from admin.", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 16),
                _inputField(controller: _gatePassReasonController, label: "Reason for early leave", icon: Icons.edit_note, isDark: isDark),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (picked != null) setState(() => _selectedLeaveTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      border: Border.all(color: _selectedLeaveTime != null ? const Color(0xFF6366F1) : (isDark ? Colors.white12 : Colors.grey.shade300)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: _selectedLeaveTime != null ? const Color(0xFF6366F1) : Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedLeaveTime == null ? "Select Leave Time" : "Leaving at: ${_selectedLeaveTime!.format(context)}",
                          style: TextStyle(color: _selectedLeaveTime != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey, fontWeight: _selectedLeaveTime != null ? FontWeight.w600 : FontWeight.normal),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _requestEarlyLeavingGatePass,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text("Request Gate Pass", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("MY GATE PASSES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _isLoadingGatePasses
              ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF6366F1))))
              : _gatePasses.isEmpty
                  ? _emptyState(isDark, icon: Icons.inbox_outlined, message: "No gate pass requests yet.")
                  : Column(children: _gatePasses.map(_buildGatePassItem).toList()),
        ],
      ),
    );
  }

  Widget _buildMyIdPage(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final fn = (_user['firstName'] ?? '').toString().replaceAll('null', '').trim();
    final ln = (_user['lastName'] ?? '').toString().replaceAll('null', '').trim();
    final fullName = "$fn $ln".trim();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // ID Card
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("IOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: const Text("SECURITY", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                ),
                child: _buildSafeAvatar(_user["photoUrl"]?.toString(), radius: 52),
              ),
              const SizedBox(height: 16),
              Text(
                fullName.isEmpty ? "Guard" : fullName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _user["designation"]?.toString().replaceAll('null', '') ?? "Security Guard",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(_user["department"]?.toString().replaceAll('null', '') ?? "Security Sentry", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: QrImageView(data: _user["id"]?.toString() ?? "GUARD", version: QrVersions.auto, size: 150.0),
              ),
              const SizedBox(height: 12),
              Text(
                "GRD-${(_user['id']?.toString() ?? '').length >= 8 ? (_user['id']!.toString().substring(0, 8)).toUpperCase() : ''}",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Sign out
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── ITEM BUILDERS ───────────────────────────────────────────────────────────

  Widget _buildVisitorCard(dynamic v, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: const Color(0xFF10B981)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    _buildSafeAvatar(v["photoUrl"]?.toString(), radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${v["firstName"]} ${v["lastName"]}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          const SizedBox(height: 3),
                          Text(v["company"] ?? "—", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text("Host: ${v["hostName"] ?? "—"}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _checkoutVisitor(v["id"].toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: const Text("Check Out", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatePassItem(dynamic pass) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final status = pass["approvalStatus"];
    final isUsed = pass["isUsed"] == true;
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_actions_outlined;

    if (status == "Approved") {
      statusColor = isUsed ? Colors.grey : const Color(0xFF10B981);
      statusIcon = isUsed ? Icons.check_box_outlined : Icons.qr_code;
    } else if (status == "Rejected") {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pass["reason"] ?? "Early Leave", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(children: [const Icon(Icons.schedule, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(pass["leaveTime"] ?? "—", style: const TextStyle(color: Colors.grey, fontSize: 12))]),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(isUsed ? "Redeemed" : (status ?? "Pending"), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: status == "Approved" && !isUsed ? () => _showGatePassQrDialog(pass["passCode"]) : null,
                      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(statusIcon, color: statusColor, size: 22)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MICRO WIDGETS ────────────────────────────────────────────────────────────

  Widget _glassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white),
            boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Icon(icon, color: const Color(0xFF10B981), size: 18),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
    ]);
  }

  Widget _timeCol(String label, String time) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(time, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
    ]);
  }

  Widget _actionTile({required IconData icon, required String label, required Color color, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String label, required IconData icon, required bool isDark}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: const Color(0xFF10B981)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _emptyState(bool isDark, {required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(children: [
        Icon(icon, color: Colors.grey, size: 28),
        const SizedBox(width: 14),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14))),
      ]),
    );
  }
}
