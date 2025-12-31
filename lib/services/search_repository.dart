import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';
import '../models/reel.dart';

class SearchRepository {
  Future<Map<String, dynamic>> search({
    required String query,
    String category = 'All',
    String sort = 'latest',
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.apiRoot}/search').replace(queryParameters: {
        'q': query,
        'category': category,
        'sort': sort,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> resultsJson = data['results'];
        
        return {
          'results': resultsJson.map((json) => Reel.fromMap(json)).toList(),
          'isFallback': data['isFallback'] ?? false,
          'message': data['message'],
        };
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    try {
      final uri = Uri.parse('${ApiConfig.apiRoot}/search/suggestions').replace(queryParameters: {'q': query});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getTrending() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.apiRoot}/search/trending'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
