import 'package:dio/dio.dart';
import '../utils/api_config.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class AuthService {

  static String get baseUrl => ApiConfig.baseUrl;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  // Update Profile
  Future<Map<String, dynamic>> updateProfile(String token, String name, String email, File? imageFile) async {
    try {
      String url = '$baseUrl/profile';
      print("🔵 [DEBUG] Updating Profile: $url");
      print("   Name: $name, Email: $email");
      if (imageFile != null) print("   Image: ${imageFile.path}");
      
      FormData formData = FormData.fromMap({
        'name': name,
        'email': email,
        if (imageFile != null)
          'profile_pic': await MultipartFile.fromFile(
            imageFile.path, 
            filename: imageFile.path.split(Platform.pathSeparator).last,
            contentType: MediaType('image', 'jpeg'), // Explicit content type
          ),
      });

      final response = await _dio.put(
        url,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print("✅ [DEBUG] Update Profile Response: ${response.statusCode}");
      return response.data;
    } on DioException catch (e) {
      print("🔴 [DEBUG] Update Profile Failed: ${e.response?.statusCode} - ${e.response?.data}");
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getSavedReels(String token) async {
    try {
      final response = await _dio.get(
        '$baseUrl/saved-reels',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.data is List) {
          return response.data;
      }
      return [];
    } catch (e) {
      print("Get Saved Reels Error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/signup',
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _dio.post(
        '$baseUrl/send-otp',
        data: {'email': email},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post(
        '$baseUrl/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp(String email, String otp, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/reset-password-with-otp',
        data: {'email': email, 'otp': otp, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> googleLogin(
    String email,
    String? name,
    String? googleId,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/google-login',
        data: {'email': email, 'name': name, 'googleId': googleId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '$baseUrl/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }





  Future<Map<String, dynamic>> updatePassword(
    String token,
    String newPassword,
    String? oldPassword,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/update-password',
        data: {
          'password': newPassword,
          if (oldPassword != null) 'oldPassword': oldPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    print("🔴 Dio Error: ${error.message}");
    if (error.response != null) {
      print("🔴 Response Data: ${error.response?.data}");
      print("🔴 Status Code: ${error.response?.statusCode}");
      
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
         // Check for 'message' or 'error' key
         if (data['message'] != null) return data['message'].toString();
         if (data['error'] != null) return data['error'].toString();
      } else if (data is String) {
         return data;
      }
    }
    return 'Connection Error: ${error.message}';
  }
}
