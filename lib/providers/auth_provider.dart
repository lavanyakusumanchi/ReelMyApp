import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'dart:io';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token; 

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  
  bool get isAdmin => _user != null && _user!['role'] == 'admin';

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      _token = token; 
      _isAuthenticated = true;
      notifyListeners(); 
      fetchProfile(); 
    }
  }
  

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      
      if (data['token'] != null) {
        await _storage.write(key: 'token', value: data['token']);
        _token = data['token'];
        if (data['user'] != null) {
           _user = data['user'];
        }
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login Error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signup(name, email, password);
      // Removed auto-login to allow manual redirection


      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login Error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.sendOtp(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.verifyOtp(email, otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.resetPasswordWithOtp(email, otp, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;


  Future<bool> googleLogin() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Placeholder to sync state
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Force account picker to show every time
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the picker
        _isLoading = false;
        _isGoogleLoading = false;
        notifyListeners();
        return false;
      }

      final data = await _authService.googleLogin(
        googleUser.email,
        googleUser.displayName ?? '',
        googleUser.id,
      );

      if (data['token'] != null) {
        await _storage.write(key: 'token', value: data['token']);
        _token = data['token']; // Update memory value
        if (data['user'] != null) {
           _user = data['user'];
        }
        _isAuthenticated = true;

      }

      _isGoogleLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('🔴 [REAL MODE] Login Error: $e');
      _errorMessage = "Sign In Failed: $e";
      _isGoogleLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<dynamic> _savedReels = [];
  List<dynamic> get savedReels => _savedReels;

  Future<void> fetchSavedReels() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      final reels = await _authService.getSavedReels(token);
      _savedReels = reels;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _user;
  Map<String, dynamic>? get user => _user;

  Future<void> fetchProfile() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = await _authService.getUserProfile(token);
      print("🔵 [DEBUG] Profile Fetched: $userData");
      _user = userData;
    } catch (e) {
      print("Error fetching profile: $e");
      _errorMessage = "Failed to load profile: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name, String email, File? imageFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception("Not authenticated");

      final response = await _authService.updateProfile(token, name, email, imageFile);
      
     
      await fetchProfile();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }



  Future<bool> updatePassword(String newPassword, [String? oldPassword]) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) throw Exception("Not authenticated");

      await _authService.updatePassword(token, newPassword, oldPassword);

      // Password updated successfully. Refresh profile status.
      await fetchProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
