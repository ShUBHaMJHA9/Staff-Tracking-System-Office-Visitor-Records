import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'dart:ui';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _qrController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = "";
  bool _otpSent = false;
  bool _showManualToken = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _otpSent = false;
          _errorMessage = "";
          _phoneController.clear();
          _otpController.clear();
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  void _checkAutoLogin() async {
    try {
      final user = await ApiService().getSessionUser();
      if (user.isNotEmpty && user.containsKey("role")) {
        final role = user["role"];
        if (!mounted) return;
        if (role == "SecurityGuard") {
          Navigator.pushReplacementNamed(context, '/guard');
        } else if (role == "Staff") {
          Navigator.pushReplacementNamed(context, '/staff');
        } else if (role == "Admin") {
          await ApiService().logout();
          setState(() {
            _errorMessage = "Admin access is restricted to the web dashboard.";
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  void _handleRequestOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter mobile number.");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await ApiService().requestOtp(_phoneController.text.trim());
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Navigate to dedicated OTP screen
      final role = _tabController.index == 0 ? 'Staff' : 'SecurityGuard';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phone: _phoneController.text.trim(),
            role: role,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _handleVerifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter OTP.");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      const mockDeviceId = "FLUTTER_DEV_DEVICE_1";
      final user = await ApiService().verifyOtp(
        _phoneController.text.trim(),
        _otpController.text.trim(),
        mockDeviceId
      );

      if (!mounted) return;
      _navigateBasedOnRole(user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _handleQrLogin(String token) async {
    if (token.trim().isEmpty) {
      setState(() => _errorMessage = "Invalid QR Token.");
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      const mockDeviceId = "FLUTTER_DEV_DEVICE_1";
      final user = await ApiService().qrLogin(token.trim(), mockDeviceId);
      if (!mounted) return;
      _navigateBasedOnRole(user);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _navigateBasedOnRole(Map<String, dynamic> user) async {
    final role = user["role"] ?? "Staff";
    if (role == "Admin") {
      setState(() {
        _errorMessage = "Admin portal must be viewed on desktop web dashboard.";
        _isLoading = false;
      });
      await ApiService().logout();
      return;
    }
    Navigator.pushReplacementNamed(context, role == "SecurityGuard" ? "/guard" : "/staff");
  }

  void _openScanner() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _errorMessage = "Camera permission is required to scan QR tokens.");
      return;
    }

    bool hasScanned = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Scanner",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const Text("Scan QR Token", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(width: 48), // for layout balance
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text("Align QR Code within the frame to authenticate", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 40),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 320,
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.8), width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 40, spreadRadius: 5)
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MobileScanner(
                                  onDetect: (capture) {
                                    if (hasScanned) return;
                                    final List<Barcode> barcodes = capture.barcodes;
                                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                                      hasScanned = true;
                                      Navigator.pop(ctx);
                                      _handleQrLogin(barcodes.first.rawValue!);
                                    }
                                  },
                                ),
                                const _ScannerOverlay(),
                                // Faint icon overlay in the background
                                const Center(
                                  child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          )
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative glowing orbs in background
              Positioned(
                top: -50, left: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.2), blurRadius: 100)]
                  ),
                ),
              ),
              Positioned(
                bottom: -100, right: -50,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.15), blurRadius: 120)]
                  ),
                ),
              ),
              // Scanner Button Top Right
              Positioned(
                top: 16, right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _openScanner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text("Scan QR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Glassmorphism Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                                boxShadow: [
                                  if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 24, spreadRadius: -4)
                                ]
                              ),
                              child: Column(
                                children: [
                                  // Logo
                                  Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                                    ),
                                    child: const Center(
                                      child: Text("IOD", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Outfit')),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text("IOD Security Gate", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                                  const SizedBox(height: 8),
                                  Text("Guard & Staff Mobile Authentication", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
                                  const SizedBox(height: 32),

                                  // Custom Tabs
                                  Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TabBar(
                                      controller: _tabController,
                                      indicator: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                                        ]
                                      ),
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      indicatorPadding: const EdgeInsets.all(4),
                                      labelColor: Colors.blue[600],
                                      unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
                                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      dividerColor: Colors.transparent,
                                      tabs: const [
                                        Tab(text: "Staff"),
                                        Tab(text: "Guard"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  if (_errorMessage.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.withOpacity(0.3))
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],

                                  // Phone / OTP Form
                                  _showManualToken 
                                  ? TextField(
                                      controller: _qrController,
                                      decoration: InputDecoration(
                                        labelText: "Paste Manual Token",
                                        prefixIcon: const Icon(Icons.key),
                                        filled: true,
                                        fillColor: isDark ? Colors.black12 : Colors.white,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        TextField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          enabled: !_otpSent,
                                          decoration: InputDecoration(
                                            labelText: "Mobile Number",
                                            prefixIcon: const Icon(Icons.phone_outlined),
                                            filled: true,
                                            fillColor: isDark ? Colors.black12 : Colors.white,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          ),
                                        ),
                                        if (_otpSent) ...[
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: _otpController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              labelText: "Enter Secure OTP",
                                              prefixIcon: const Icon(Icons.password),
                                              filled: true,
                                              fillColor: isDark ? Colors.black12 : Colors.white,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),

                                  const SizedBox(height: 32),
                                  
                                  // Submit Button
                                  _isLoading 
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: _showManualToken 
                                              ? () => _handleQrLogin(_qrController.text) 
                                              : (_otpSent ? _handleVerifyOtp : _handleRequestOtp),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: Text(
                                            _showManualToken ? "Login with Token" : (_otpSent ? "Verify & Login" : "Send Secure OTP"),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                                          ),
                                        ),
                                      )
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Footer Toggle
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _showManualToken = !_showManualToken;
                                _errorMessage = "";
                              });
                            },
                            style: TextButton.styleFrom(foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600]),
                            child: Text(
                              _showManualToken ? "Switch to Mobile Number Login" : "Login with Token Manually",
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay({Key? key}) : super(key: key);

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value * (320 - 4), // 320 is height of container, 4 is line height
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              boxShadow: [
                BoxShadow(color: Colors.blueAccent.withOpacity(0.8), blurRadius: 15, spreadRadius: 3),
                BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
              ]
            ),
          ),
        );
      },
    );
  }
}
