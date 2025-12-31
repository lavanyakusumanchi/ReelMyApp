import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/api_config.dart';

class AdminProvider with ChangeNotifier {
  final Dio _dio = Dio();
  
  // State
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  List<dynamic> _reels = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get stats => _stats;
  List<dynamic> get users => _users;
  List<dynamic> get reels => _reels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch Dashboard Stats
  Future<void> fetchStats(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _dio.get(
        ApiConfig.getFullUrl('/api/admin/stats'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _stats = response.data;
    } catch (e) {
      _error = e.toString();
      print("Fetch Stats Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Users
  Future<void> fetchUsers(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        ApiConfig.getFullUrl('/api/admin/users'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _users = response.data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch Specific User Reels
  Future<List<dynamic>> fetchUserReels(String userId, String token) async {
    try {
      final response = await _dio.get(
        ApiConfig.getFullUrl('/api/reels/user/$userId'), // Reusing public endpoint or create new admin one
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      print("Error fetching user reels: $e");
      return [];
    }
  }

  // User Actions
  Future<bool> manageUser(String userId, String action, String token) async {
    try {
      await _dio.post(
        ApiConfig.getFullUrl('/api/admin/users/$userId/$action'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Refresh list
      await fetchUsers(token);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Fetch Reels for Moderation
  Future<void> fetchReels(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        ApiConfig.getFullUrl('/api/admin/reels'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _reels = response.data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reel Actions
  Future<bool> manageReel(String reelId, String action, String token) async {
    try {
      await _dio.post(
        ApiConfig.getFullUrl('/api/admin/reels/$reelId/$action'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Refresh list
      await fetchReels(token);
      await fetchStats(token); // Update stats as well
      return true;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
         _error = e.response?.data['message'] ?? e.message;
      } else {
         _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  // Settings State
  Map<String, dynamic>? _settings;
  Map<String, dynamic>? get settings => _settings;

  Future<void> fetchSettings(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        ApiConfig.getFullUrl('/api/admin/settings'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _settings = response.data;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSetting(Map<String, dynamic> updates, String token) async {
    try {
      final response = await _dio.put(
        ApiConfig.getFullUrl('/api/admin/settings'),
        data: updates,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _settings = response.data;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetAllUsers(String token) async {
     try {
       await _dio.delete(
         ApiConfig.getFullUrl('/api/admin/danger/users'),
         options: Options(headers: {'Authorization': 'Bearer $token'}),
       );
       await fetchStats(token); // Update stats
       await fetchUsers(token);
       return true;
     } catch (e) {
       _error = e.toString();
       return false;
     }
  }

  Future<bool> clearAllReels(String token) async {
     try {
       await _dio.delete(
         ApiConfig.getFullUrl('/api/admin/danger/reels'),
         options: Options(headers: {'Authorization': 'Bearer $token'}),
       );
       await fetchStats(token);
       await fetchReels(token);
       return true;
     } catch (e) {
       _error = e.toString();
       return false;
     }
  }
}
