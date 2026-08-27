import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/location_model.dart';
import 'storage_service.dart';

class ApiService {
  // Backend API
  final String baseUrl = "https://where-am-i-silk.vercel.app";

  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (withAuth) {
      String? token = await _storageService.getToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // =========================
  // REGISTER
  // =========================
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    print('================ REGISTER ================');
    print('URL: $url');
    print('Email: $email');

    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE: ${response.body}');
      print('==========================================');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      String errorMessage = 'Unknown error';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }

      throw Exception(
        'Register failed (${response.statusCode}): $errorMessage',
      );
    } catch (e) {
      print('REGISTER ERROR: $e');
      rethrow;
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['token'] != null) {
        await _storageService.saveToken(data['token']);
      }

      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // =========================
  // VERIFY OTP
  // =========================
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify OTP: ${response.body}');
    }
  }

  // =========================
  // RESEND OTP
  // =========================
  Future<void> resendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/resend-otp'),
      headers: await _getHeaders(),
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resend OTP: ${response.body}');
    }
  }

  // =========================
  // GET CURRENT USER
  // =========================
  Future<UserModel> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: await _getHeaders(withAuth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return UserModel.fromJson(data['user']);
    } else {
      throw Exception('Failed to load user profile: ${response.body}');
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: await _getHeaders(withAuth: true),
      );
    } catch (e) {
      // Ignore error
    }

    await _storageService.clearToken();
  }

  // =========================
  // CREATE CHECK-IN
  // =========================
  Future<LocationModel> createCheckIn(
    double lat,
    double lng,
    double accuracy, {
    String? description,
    String? locationName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/checking');

    final request = http.MultipartRequest('POST', uri);

    String? token = await _storageService.getToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['accuracy'] = accuracy.toString();
    request.fields['locationName'] = locationName ?? 'Shared Location';
    request.fields['description'] = description ?? 'Live shared location from app';

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      return LocationModel.fromJson(data['checkin']);
    } else {
      throw Exception('Failed to share location: ${response.body}');
    }
  }

  // =========================
  // GET CHECK-INS
  // =========================
  Future<List<LocationModel>> getCheckIns({bool my = false}) async {
    String url = '$baseUrl/api/checking';

    if (my) {
      url += '?my=true';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(withAuth: my),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List<dynamic> checkins = data['checkins'];

      return checkins.map((e) => LocationModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load check-ins: ${response.body}');
    }
  }

  // =========================
  // SEARCH USERS
  // ค้นหาผู้ใช้จาก check-ins (deduplicate by user id)
  // กรองด้วยชื่อที่ส่งมา (case-insensitive)
  // =========================
  Future<List<UserModel>> searchUsers(String query) async {
    final checkIns = await getCheckIns();

    // สร้าง map ของ user_id → UserModel (เพื่อ deduplicate)
    final Map<int, UserModel> userMap = {};

    for (final checkIn in checkIns) {
      final user = checkIn.user;
      if (user != null && !userMap.containsKey(user.id)) {
        userMap[user.id] = user;
      }
    }

    // กรองด้วย query
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return userMap.values.toList();
    }

    return userMap.values
        .where((u) => u.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // =========================
  // GET FRIEND CHECK-INS
  // ดึง check-ins ทั้งหมด แล้วกรองให้เหลือเฉพาะ user_ids ที่ระบุ
  // คืนค่าเฉพาะ check-in ล่าสุดของแต่ละคน
  // =========================
  Future<Map<int, LocationModel>> getLatestCheckInsForFriends(
    List<int> friendIds,
  ) async {
    if (friendIds.isEmpty) return {};

    final checkIns = await getCheckIns();

    // Group check-ins ตาม userId และเก็บเฉพาะอันล่าสุด
    final Map<int, LocationModel> latestMap = {};

    for (final checkIn in checkIns) {
      final userId = checkIn.userId;
      if (userId == null || !friendIds.contains(userId)) continue;

      if (!latestMap.containsKey(userId)) {
        latestMap[userId] = checkIn;
      } else {
        final existing = latestMap[userId]!;
        final existingTime = DateTime.tryParse(existing.createdAt) ?? DateTime(0);
        final newTime = DateTime.tryParse(checkIn.createdAt) ?? DateTime(0);
        if (newTime.isAfter(existingTime)) {
          latestMap[userId] = checkIn;
        }
      }
    }

    return latestMap;
  }
}
