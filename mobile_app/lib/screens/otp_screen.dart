import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'face_auth_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String role;

  const OtpScreen({super.key, required this.phone, required this.role});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  String _errorMessage = '';

  // Timer
  static const int _totalSeconds = 60;
  int _remainingSeconds = _totalSeconds;
  Timer? _countdownTimer;

  bool get _isGuard => widget.role == 'SecurityGuard';
  Color get _primaryColor =>
      _isGuard ? const Color(0xFF6366F1) : const Color(0xFF2563EB); // Modern indigo / blue

  @override
  void initState() {
    super.initState();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });

    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _remainingSeconds = _totalSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String get _fullOtp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 4 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      _focusNodes[(digits.length - 1).clamp(0, 3)].requestFocus();
      setState(() {});
      if (digits.length >= 4) _handleVerify();
      return;
    }
    
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    // Handle backspace automatically moving to previous field
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    setState(() {});
    
    if (_fullOtp.length == 4) {
      // Small delay so user sees the last digit entered before loading starts
      Future.delayed(const Duration(milliseconds: 150), _handleVerify);
    }
  }

  Future<void> _handleVerify() async {
    final otp = _fullOtp;
    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter all 4 digits.');
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const mockDeviceId = 'FLUTTER_DEV_DEVICE_1';
      final user = await ApiService().verifyOtp(widget.phone, otp, mockDeviceId);
      if (!mounted) return;
      
      final role = user['role'] ?? 'Staff';
      if (role == 'Admin') {
        setState(() {
          _errorMessage = 'Admin access is restricted to the web dashboard.';
          _isLoading = false;
        });
        await ApiService().logout();
        return;
      }
      
      // Navigate to Face ID step instead of directly to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FaceAuthScreen(role: role),
        ),
      );
    } catch (e) {
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _handleResend() async {
    try {
      await ApiService().requestOtp(widget.phone);
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              // Decorative glowing orbs
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor.withOpacity(0.15),
                    boxShadow: [BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 100)]
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock_outline, size: 40, color: _primaryColor),
                          ),
                          const SizedBox(height: 24),
                          
                          Text(
                            'Secure Verification',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                              letterSpacing: -1,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280), height: 1.4),
                              children: [
                                const TextSpan(text: 'We\'ve sent a 4-digit code to\n'),
                                TextSpan(
                                  text: '+91 ${widget.phone}',
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 48),
                          
                          // OTP Input Fields
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(4, (index) => _buildOtpField(index, isDark)),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 24.0),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3))
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Resend Timer
                          Center(
                            child: _remainingSeconds > 0
                                ? Text(
                                    'Resend code in 00:${_remainingSeconds.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _handleResend,
                                    style: TextButton.styleFrom(foregroundColor: _primaryColor),
                                    child: const Text('Resend code now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading || _fullOtp.length < 4 ? null : _handleVerify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                disabledBackgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                elevation: 10,
                                shadowColor: _primaryColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                    )
                                  : Text(
                                      'Verify & Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: _isLoading || _fullOtp.length < 4
                                            ? (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                                            : Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Center(child: Text('Demo OTP: 1234', style: TextStyle(color: isDark ? Colors.white30 : Colors.black26))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index, bool isDark) {
    final isFocused = _focusNodes[index].hasFocus;
    final isFilled = _controllers[index].text.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 75,
      width: (MediaQuery.of(context).size.width - 48 - (3 * 16)) / 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(isFocused ? 0.05 : 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused ? _primaryColor : (isFilled ? (isDark ? Colors.white30 : Colors.black26) : Colors.transparent),
          width: isFocused ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (!isDark && isFocused) BoxShadow(color: _primaryColor.withOpacity(0.2), blurRadius: 15, spreadRadius: 2),
          if (!isDark && !isFocused) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 4, 
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
          cursorColor: _primaryColor,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) => _onDigitChanged(index, val),
        ),
      ),
    );
  }
}
