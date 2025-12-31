import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
 
  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  static String? _customBaseUrl;

  static const String _prefKey = 'custom_base_url_ip';

  static Future<void> setCustomBaseUrl(String ip) async {
    if (ip.isEmpty) {
      _customBaseUrl = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } else {
      _customBaseUrl = 'http://$ip:5001/api/auth';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, ip);
    }
  }

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_prefKey);
    if (ip != null && ip.isNotEmpty) {
      _customBaseUrl = 'http://$ip:5001/api/auth';
      print('🔧 [ApiConfig] Loaded Custom IP: $ip');
    }
  }

  static String get baseUrl {
    if (_customBaseUrl != null) {
      return _customBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return '$_envBaseUrl/auth';
    }

    if (Platform.isAndroid) {
      // Use localhost (127.0.0.1) which maps to host machine via ADB reverse
      return 'http://127.0.0.1:5001/api/auth';
    }
    // Fallback for iOS or other platforms
    return 'http://127.0.0.1:5001/api/auth';
  }


  static String get apiRoot {
    return baseUrl.replaceAll('/auth', '');
  }


  static String get mediaBaseUrl {
    var root = apiRoot.replaceAll('/api', '');
    if (root.endsWith('/')) {
      root = root.substring(0, root.length - 1);
    }
    print('🎥 [ApiConfig] Media Base URL: $root');
    return root;
  }

  static String getFullVideoUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath; 
    }

   
    String path = relativePath.replaceAll('\\', '/');
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final fullUrl = '$mediaBaseUrl$path';
    print('🎥 [ApiConfig] Full Video URL: $fullUrl');
    return fullUrl;
  }


  static String getFullUrl(String path) {
    if (path.startsWith('http')) return path;
    
    // Fix Windows paths
    String cleanPath = path.replaceAll('\\', '/');
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    
    return '$mediaBaseUrl$cleanPath';
  }
}
