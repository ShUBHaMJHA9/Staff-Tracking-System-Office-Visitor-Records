// c:\Users\jha95\OneDrive\Documents\PROJECT\enterprise-oms\mobile_app\lib\services\api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cloudflare Tunnel URL — stable, no 503s, no "click to continue" pages
  static const String defaultBaseUrl = "https://carlo-concert-roommates-pan.trycloudflare.com/api/v1";
  String baseUrl = defaultBaseUrl;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("iod_jwt_token") ?? "";
    return {
      "Content-Type": "application/json",
      "Authorization": token.isNotEmpty ? "Bearer $token" : ""
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("iod_jwt_token", data["token"] ?? "");
      await prefs.setString("iod_active_user", jsonEncode(data["user"]));
      return data["user"];
    } else {
      throw Exception(data["message"] ?? "Authentication failed.");
    }
  }

  Future<void> requestOtp(String phone) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/request-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Failed to request OTP.");
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, String deviceId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone, "otp": otp, "deviceId": deviceId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("iod_jwt_token", data["token"] ?? "");
      await prefs.setString("iod_active_user", jsonEncode(data["user"]));
      return data["user"];
    } else {
      throw Exception(data["message"] ?? "Invalid OTP.");
    }
  }

  Future<bool> verifyFace(String imagePath) async {
    final headers = await _getHeaders();
    final request = http.MultipartRequest('POST', Uri.parse("$baseUrl/auth/verify-face"));
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('faceImage', imagePath));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return true;
    } else {
      String errorMessage = "Face verification failed.";
      try {
        final data = jsonDecode(response.body);
        errorMessage = data["message"] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("iod_jwt_token");
    if (token == null || token.isEmpty) return;

    final response = await http.post(
      Uri.parse("$baseUrl/duty/location"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({"latitude": lat, "longitude": lng}),
    );
    if (response.statusCode != 200) {
      print("Failed to update location: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> qrLogin(String qrToken, String deviceId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/qr-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"qrToken": qrToken, "deviceId": deviceId}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("iod_jwt_token", data["token"] ?? "");
      await prefs.setString("iod_active_user", jsonEncode(data["user"]));
      return data["user"];
    } else {
      throw Exception(data["message"] ?? "Invalid or expired QR Token.");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("iod_jwt_token");
    await prefs.remove("iod_active_user");
  }

  Future<Map<String, dynamic>> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("iod_active_user") ?? "";
    if (userJson.isEmpty) return {};
    return jsonDecode(userJson);
  }

  // Fetch fresh profile from backend (always current, no stale cache)
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/auth/me"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update local cache too
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("iod_active_user", jsonEncode(data));
        return data;
      }
    } catch (_) {}
    // Fallback to cached session
    return getSessionUser();
  }

  Future<Map<String, dynamic>> checkIn(String method, String ipAddress) async {
    final response = await http.post(
      Uri.parse("$baseUrl/attendance/check-in"),
      headers: await _getHeaders(),
      body: jsonEncode({"method": method, "ipAddress": ipAddress}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Clock-in failed.");
    }
  }

  Future<Map<String, dynamic>> checkOut() async {
    final response = await http.post(
      Uri.parse("$baseUrl/attendance/check-out"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Clock-out failed.");
    }
  }

  Future<Map<String, dynamic>> startDuty(String destination, String reason) async {
    final response = await http.post(
      Uri.parse("$baseUrl/duty/start"),
      headers: await _getHeaders(),
      body: jsonEncode({"destination": destination, "reason": reason}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to start office duty.");
    }
  }

  Future<Map<String, dynamic>> stopDuty() async {
    final response = await http.post(
      Uri.parse("$baseUrl/duty/stop"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to stop office duty.");
    }
  }

  Future<void> logCoordinate(String dutyLogId, double lat, double lng) async {
    final response = await http.post(
      Uri.parse("$baseUrl/duty/log-coordinate"),
      headers: await _getHeaders(),
      body: jsonEncode({
        "dutyLogId": dutyLogId,
        "latitude": lat,
        "longitude": lng
      }),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data["message"] ?? "Failed to log location coordinates.");
    }
  }

  Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitor/employees"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load employee list.");
    }
  }

  Future<Map<String, dynamic>> checkInVisitor(Map<String, dynamic> details) async {
    final response = await http.post(
      Uri.parse("$baseUrl/visitor/check-in"),
      headers: await _getHeaders(),
      body: jsonEncode(details),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to register visitor.");
    }
  }

  Future<List<dynamic>> getActiveVisitors() async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitor/active"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load active visitors.");
    }
  }

  Future<Map<String, dynamic>> checkoutVisitor(String id) async {
    final response = await http.post(
      Uri.parse("$baseUrl/visitor/check-out/$id"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to checkout visitor.");
    }
  }

  Future<Map<String, dynamic>> registerStaffAttendance(String userId, String method, String direction) async {
    final response = await http.post(
      Uri.parse("$baseUrl/attendance/register"),
      headers: await _getHeaders(),
      body: jsonEncode({
        "userId": userId,
        "method": method,
        "direction": direction
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to register staff attendance.");
    }
  }

  // Dedicated endpoint to check guard's current active shift — avoids full history parse
  Future<Map<String, dynamic>> getActiveShift() async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/active-shift"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to check active shift status.");
    }
  }

  Future<List<dynamic>> getAttendanceHistory() async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/history"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load attendance history.");
    }
  }

  Future<Map<String, dynamic>> lookupVisitorByCard(String cardId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/visitor/lookup/$cardId"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to lookup visitor by card.");
    }
  }

  Future<Map<String, dynamic>> getEmployeeAttendanceState(String employeeId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/attendance/employee/$employeeId"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to load employee attendance state.");
    }
  }

  Future<Map<String, dynamic>> requestGatePass(String reason, String leaveTime) async {
    final response = await http.post(
      Uri.parse("$baseUrl/gatepass/request"),
      headers: await _getHeaders(),
      body: jsonEncode({"reason": reason, "leaveTime": leaveTime}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to request gate pass.");
    }
  }

  Future<List<dynamic>> getMyGatePasses() async {
    final response = await http.get(
      Uri.parse("$baseUrl/gatepass/my-passes"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load gate passes.");
    }
  }

  Future<Map<String, dynamic>> scanGatePass(String passCode) async {
    final response = await http.post(
      Uri.parse("$baseUrl/gatepass/scan/$passCode"),
      headers: await _getHeaders(),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "Failed to redeem gate pass.");
    }
  }
}
