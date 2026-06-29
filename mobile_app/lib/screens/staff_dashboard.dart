// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\mobile_app\lib\screens\staff_dashboard.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'face_auth_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _user = {};
  bool _isLoading = true;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  int _selectedSectionIndex = 0;
  final GlobalKey _profileSectionKey = GlobalKey();
  final GlobalKey _attendanceSectionKey = GlobalKey();
  final GlobalKey _dutySectionKey = GlobalKey();
  final GlobalKey _gatePassSectionKey = GlobalKey();
  final GlobalKey _historySectionKey = GlobalKey();
  
  // Attendance states
  bool _isClockedIn = false;
  String _clockInTime = "--:--";
  String _clockOutTime = "--:--";
  String _activeLogId = "";

  // GPS Office Duty states
  bool _isOnFieldDuty = false;
  String _dutyLogId = "";
  String _destination = "";
  String _reason = "";
  int _coordCount = 0;
  
  // Attendance History states
  List<dynamic> _history = [];
  bool _isLoadingHistory = false;

  // Gate Pass states
  List<dynamic> _gatePasses = [];
  bool _isLoadingGatePasses = false;
  final _gatePassReasonController = TextEditingController();
  TimeOfDay? _selectedLeaveTime;
  
  // Form controllers
  final _destController = TextEditingController();
  final _reasonController = TextEditingController();
  final _estTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadUserSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _destController.dispose();
    _reasonController.dispose();
    _estTimeController.dispose();
    _gatePassReasonController.dispose();
    super.dispose();
  }


  Future<void> _loadUserSession() async {
    try {
      final profile = await ApiService().getProfile();
      if (!mounted) return;
      setState(() {
        _user = profile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      final session = await ApiService().getSessionUser();
      if (!mounted) return;
      setState(() {
        _user = session;
        _isLoading = false;
      });
    }
      await Future.wait([
        _loadAttendanceHistory(),
        _loadGatePasses(),
        _checkActiveLogs(),
      ]);
  }

  void _scrollToSection(GlobalKey key, int index) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
      setState(() => _selectedSectionIndex = index);
    }
  }

  Future<void> _refreshAll() async {
    await _loadUserSession();
  }

  Future<void> _loadAttendanceHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final data = await ApiService().getAttendanceHistory();
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  Future<void> _loadGatePasses() async {
    setState(() => _isLoadingGatePasses = true);
    try {
      final data = await ApiService().getMyGatePasses();
      setState(() {
        _gatePasses = data;
        _isLoadingGatePasses = false;
      });
    } catch (e) {
      debugPrint("Error loading gate passes: $e");
    }
  }

  Future<void> _checkActiveLogs() async {
    try {
      final shift = await ApiService().getActiveShift();
      debugPrint("[Staff Shift Check] Response: $shift");
      final bool isActive = shift["isActive"] == true;
      if (isActive) {
        final checkInStr = shift["checkIn"].toString();
        final checkInTimeParsed = DateTime.parse(checkInStr).toLocal();
        setState(() {
          _isClockedIn = true;
          _activeLogId = shift["logId"]?.toString() ?? "";
          _clockInTime = (() {
            final h = checkInTimeParsed.hour;
            final m = checkInTimeParsed.minute.toString().padLeft(2, '0');
            final amPm = h >= 12 ? 'PM' : 'AM';
            final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
            return "${hour.toString().padLeft(2, '0')}:$m $amPm";
          })();
          _clockOutTime = "--:--";
        });
      } else {
        setState(() {
          _isClockedIn = false;
          _clockInTime = "--:--";
          _clockOutTime = "--:--";
          _activeLogId = "";
        });
      }
    } catch (e) {
      debugPrint("Error checking active logs: $e");
    }
  }


  void _triggerBiometricScan() async {
    if (_isClockedIn) {
      _performClockOut();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FaceAuthScreen(role: 'Staff'),
        ),
      );

      if (result == true) {
        _performClockIn();
      }
    }
  }

  void _performClockIn() async {
    try {
      final res = await ApiService().checkIn("Face", "Local Mobile Device");
      final checkInTimeParsed = DateTime.parse(res["checkIn"]).toLocal();
      setState(() {
        _isClockedIn = true;
        _clockInTime = (() {
          final h = checkInTimeParsed.hour;
          final m = checkInTimeParsed.minute.toString().padLeft(2, '0');
          final amPm = h >= 12 ? 'PM' : 'AM';
          final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          return "${hour.toString().padLeft(2, '0')}:$m $amPm";
        })();
        _clockOutTime = "--:--";
        _activeLogId = res["logId"] ?? "";
      });
      _loadAttendanceHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Face Biometric Verified. Check-in registered successfully."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _performClockOut() async {
    try {
      final res = await ApiService().checkOut();
      final checkOutTimeParsed = DateTime.parse(res["checkOut"]).toLocal();
      setState(() {
        _isClockedIn = false;
        _clockOutTime = (() {
          final h = checkOutTimeParsed.hour;
          final m = checkOutTimeParsed.minute.toString().padLeft(2, '0');
          final amPm = h >= 12 ? 'PM' : 'AM';
          final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          return "${hour.toString().padLeft(2, '0')}:$m $amPm";
        })();
        _activeLogId = "";
      });
      if (_isOnFieldDuty) {
        _stopOfficeDuty();
      }
      _loadAttendanceHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clock-out registered successfully."),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _startOfficeDuty() async {
    final dest = _destController.text.trim();
    final reason = _reasonController.text.trim();
    final estTime = _estTimeController.text.trim();
    if (dest.isEmpty || reason.isEmpty || estTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill destination, reason, and estimated time fields.")),
      );
      return;
    }

    final pNotification = await Permission.notification.request();
    var pLocation = await Permission.locationWhenInUse.request();
    
    if (pLocation.isGranted) {
      pLocation = await Permission.locationAlways.request();
    }

    if (!pLocation.isGranted || !pNotification.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location and Notification permissions are strictly required for field duty tracking."))
      );
      return;
    }

    try {
      final res = await ApiService().startDuty(dest, reason);
      setState(() {
        _isOnFieldDuty = true;
        _dutyLogId = res["id"];
        _destination = dest;
        _reason = "$reason (Est. Time: $estTime)";
        _coordCount = 0;
      });

      _destController.clear();
      _reasonController.clear();
      _estTimeController.clear();

      FlutterBackgroundService().invoke('setAsForeground');
      FlutterBackgroundService().startService();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Field Office Duty started. GPS tracking active in background."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _stopOfficeDuty() async {
    try {
      await ApiService().stopDuty();
      FlutterBackgroundService().invoke('stopService');
      setState(() {
        _isOnFieldDuty = false;
        _dutyLogId = "";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Field Office Duty completed. Tracking stopped."),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _requestEarlyLeavingGatePass() async {
    final reason = _gatePassReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a reason for leaving early.")),
      );
      return;
    }
    if (_selectedLeaveTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your scheduled leave time.")),
      );
      return;
    }

    final leaveTimeStr = _selectedLeaveTime!.format(context);

    try {
      await ApiService().requestGatePass(reason, leaveTimeStr);
      _gatePassReasonController.clear();
      setState(() {
        _selectedLeaveTime = null;
      });
      _loadGatePasses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gate Pass requested. Waiting for admin approval."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _handleLogout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Widget _buildSafeAvatar(String? url, {double radius = 30}) {
    final isValidUrl = url != null && url.isNotEmpty && url != "null" && url != "string" && url.length > 5;
    final initials = (() {
      final first = (_user['firstName'] ?? '').toString().trim();
      final last = (_user['lastName'] ?? '').toString().trim();
      final value = '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.trim();
      return value.isEmpty ? 'S' : value.toUpperCase();
    })();

    if (!isValidUrl) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
              fontSize: radius * 0.8,
            ),
          ),
        ),
      );
    }
    
    final fullUrl = url!.startsWith("http") ? url : "${ApiService().baseUrl.replaceAll("/api/v1", "")}${url.startsWith("/") ? url : "/$url"}";

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
      backgroundImage: NetworkImage(fullUrl),
      onBackgroundImageError: (e, s) => print("Avatar load error: $e"),
    );
  }

  // ─── UI HELPERS ─────────────────────────────────────────────────────────────

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(msg.replaceAll('Exception: ', '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showDigitalIdCard() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "ID Card",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 40, spreadRadius: 0)
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("IOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: _buildSafeAvatar(_user["photoUrl"]?.toString(), radius: 45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (() {
                      final fn = (_user['firstName'] ?? '').toString().replaceAll('null', '').trim();
                      final ln = (_user['lastName'] ?? '').toString().replaceAll('null', '').trim();
                      return "$fn $ln".trim().toUpperCase();
                    })(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _user["designation"]?.toString().replaceAll('null', '') ?? "Staff Employee",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _user["department"]?.toString().replaceAll('null', '') ?? "Administration",
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                      data: _user["id"]?.toString() ?? "No ID",
                      version: QrVersions.auto,
                      size: 140.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "EMP-${(_user["id"]?.toString() ?? "").length >= 8 ? (_user["id"].toString().substring(0, 8)).toUpperCase() : ''}",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  void _showGatePassQrDialog(String passCode) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Gate Pass",
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Gate Pass QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Show this to the gate guard", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(data: passCode, version: QrVersions.auto, size: 180.0),
                  ),
                  const SizedBox(height: 12),
                  Text(passCode, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
    );
  }

  // ─── TAB PAGES ───────────────────────────────────────────────────────────────

  Widget _buildProfilePage(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final fn = (_user['firstName'] ?? '').toString().replaceAll('null', '').trim();
    final ln = (_user['lastName'] ?? '').toString().replaceAll('null', '').trim();
    final fullName = "$fn $ln".trim();
    final designation = (_user["designation"] ?? "Staff Employee").toString().replaceAll('null', 'Staff Employee');
    final department = (_user["department"] ?? "Administration").toString().replaceAll('null', 'Administration');

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Profile Hero Card
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                            ],
                          ),
                          child: _buildSafeAvatar(_user["photoUrl"]?.toString(), radius: 52),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName.isEmpty ? "Employee" : fullName,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$designation • $department",
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Quick info pills
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _infoPill(Icons.email_outlined, (_user["email"] ?? "").toString().replaceAll('null', ''), isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status Card
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Today's Status", Icons.today),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        label: "CHECK IN",
                        value: _clockInTime,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statBox(
                        label: "CHECK OUT",
                        value: _clockOutTime,
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statBox(
                        label: "STATUS",
                        value: _isClockedIn ? "IN" : "OUT",
                        color: _isClockedIn ? const Color(0xFF10B981) : Colors.orange,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Actions
          _sectionCard(
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
                        icon: Icons.qr_code_2,
                        label: "My ID Card",
                        onTap: _showDigitalIdCard,
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.refresh,
                        label: "Sync Data",
                        onTap: _refreshAll,
                        color: const Color(0xFF0EA5E9),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.logout,
                        label: "Sign Out",
                        onTap: _handleLogout,
                        color: const Color(0xFFEF4444),
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

  Widget _buildAttendancePage(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Hero Attendance Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isClockedIn
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (_isClockedIn ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isClockedIn ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isClockedIn ? "You're Checked In" : "Not Checked In",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isClockedIn
                      ? "Your attendance is being recorded."
                      : "Visit the gate and get scanned by a guard.",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _timeColumn("CHECK IN", _clockInTime),
                    Container(width: 1, height: 45, color: Colors.white24),
                    _timeColumn("CHECK OUT", _clockOutTime),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Self clock-in card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader("Biometric Clock-in", Icons.fingerprint),
                    const SizedBox(height: 8),
                    Text(
                      "Use face biometric to self-register attendance. Available for authorized staff only.",
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _triggerBiometricScan,
                        icon: Icon(_isClockedIn ? Icons.logout : Icons.face_retouching_natural),
                        label: Text(
                          _isClockedIn ? "Clock Out via Face Scan" : "Clock In via Face Scan",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isClockedIn ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyPage(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Duty Status Hero
          if (_isOnFieldDuty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text("LIVE GPS TRACKING", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                      const Spacer(),
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("📍 $_destination", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(_reason, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _stopOfficeDuty,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text("End Duty & Stop Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFD97706),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _sectionCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader("Start Field Duty", Icons.work_outline),
                  const SizedBox(height: 6),
                  Text(
                    "Fill in your outdoor duty details. GPS tracking will begin in the background.",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _inputField(
                    controller: _destController,
                    label: "Destination Location",
                    icon: Icons.navigation_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: _reasonController,
                    label: "Reason for Outdoor Visit",
                    icon: Icons.notes,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    controller: _estTimeController,
                    label: "Estimated Duration (e.g. 2 hours)",
                    icon: Icons.timer_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _startOfficeDuty,
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text("Start Field Duty Session", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

          // Admin Duties placeholder
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Admin Allocated Duties", Icons.assignment_outlined),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF6366F1), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("No duties allocated", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 4),
                            const Text("Duties assigned by admin will appear here.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatePassPage(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _sectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Request Gate Pass", Icons.badge_outlined),
                const SizedBox(height: 6),
                Text(
                  "Request early leave authorization. Admin approval required.",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                _inputField(
                  controller: _gatePassReasonController,
                  label: "Reason for early checkout",
                  icon: Icons.edit_note,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setState(() => _selectedLeaveTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                      border: Border.all(
                        color: _selectedLeaveTime != null ? const Color(0xFF6366F1) : (isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: _selectedLeaveTime != null ? const Color(0xFF6366F1) : Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedLeaveTime == null ? "Select Leave Time" : "Leaving at: ${_selectedLeaveTime!.format(context)}",
                          style: TextStyle(
                            color: _selectedLeaveTime != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                            fontWeight: _selectedLeaveTime != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _requestEarlyLeavingGatePass,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text("Request Gate Pass", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MY GATE PASSES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
              GestureDetector(
                onTap: _loadGatePasses,
                child: const Icon(Icons.refresh, size: 20, color: Color(0xFF6366F1)),
              ),
            ],
          ),
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

  Widget _buildHistoryPage(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Stats hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 25, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ATTENDANCE HISTORY", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text(
                      "${_history.length > 30 ? 30 : _history.length} Records",
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loadAttendanceHistory,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _isLoadingHistory
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: Color(0xFF6366F1))))
              : _history.isEmpty
                  ? _emptyState(isDark, icon: Icons.history, message: "No attendance records found.")
                  : Column(children: _history.map(_buildHistoryItem).toList()),
        ],
      ),
    );
  }

  // ─── LIST ITEM BUILDERS ───────────────────────────────────────────────────────

  Widget _buildHistoryItem(dynamic log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final checkIn = DateTime.parse(log["checkIn"]).toLocal();
    final checkOut = log["checkOut"] != null ? DateTime.parse(log["checkOut"]).toLocal() : null;
    final dateStr = "${checkIn.day.toString().padLeft(2, '0')}/${checkIn.month.toString().padLeft(2, '0')}/${checkIn.year}";
    final checkInStr = "${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}";
    final checkOutStr = checkOut != null ? "${checkOut.hour.toString().padLeft(2, '0')}:${checkOut.minute.toString().padLeft(2, '0')}" : "Active";
    String durationStr = "--";
    if (checkOut != null) {
      final diff = checkOut.difference(checkIn);
      durationStr = "${diff.inHours}h ${diff.inMinutes % 60}m";
    }
    final statusColor = checkOut != null ? const Color(0xFF10B981) : Colors.orange;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          const SizedBox(height: 3),
                          Text(log["checkInMethod"] ?? "Face ID", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(checkInStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                            const Text(" → ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(checkOutStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(durationStr, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pass["reason"] ?? "Early Leave", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(pass["leaveTime"] ?? "—", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isUsed ? 'Redeemed' : (status ?? 'Pending'), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: status == "Approved" && !isUsed ? () => _showGatePassQrDialog(pass["passCode"]) : null,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 22),
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

  // ─── MICRO WIDGET BUILDERS ────────────────────────────────────────────────────

  Widget _sectionCard({required bool isDark, required Widget child}) {
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
            boxShadow: [
              if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6))
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _statBox({required String label, required String value, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _actionTile({required IconData icon, required String label, required VoidCallback onTap, required Color color, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, bool isDark) {
    if (text.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _timeColumn(String label, String time) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(time, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _inputField({required TextEditingController controller, required String label, required IconData icon, required bool isDark}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
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
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 28),
          const SizedBox(width: 14),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── MAIN BUILD ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _buildProfilePage(isDark),
      _buildAttendancePage(isDark),
      _buildDutyPage(isDark),
      _buildGatePassPage(isDark),
      _buildHistoryPage(isDark),
    ];

    final titles = ["My Profile", "Attendance", "Field Duty", "Gate Pass", "History"];

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
            // Decorative orbs
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(isDark ? 0.12 : 0.08),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.15), blurRadius: 80)],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.08 : 0.05),
                  boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.1), blurRadius: 100)],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Center(
                            child: Text("IOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[_tabController.index],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "Staff Portal",
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Avatar
                        GestureDetector(
                          onTap: _showDigitalIdCard,
                          child: _buildSafeAvatar(_user["photoUrl"]?.toString(), radius: 20),
                        ),
                      ],
                    ),
                  ),

                  // Main Content
                  if (_isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))))
                  else
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: pages,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Premium Bottom Navigation
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withOpacity(0.9) : Colors.white.withOpacity(0.9),
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.person_outline, Icons.person, "Profile", isDark),
                    _navItem(1, Icons.access_time_outlined, Icons.access_time_filled, "Attendance", isDark),
                    _navItem(2, Icons.work_outline, Icons.work, "Duty", isDark),
                    _navItem(3, Icons.badge_outlined, Icons.badge, "Gate Pass", isDark),
                    _navItem(4, Icons.history, Icons.history, "History", isDark),
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
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.12) : Colors.transparent,
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
                color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.grey[500] : Colors.grey[600]),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
