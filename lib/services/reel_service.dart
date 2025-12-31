import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/api_config.dart';
import '../models/reel.dart';
import '../models/comment.dart';

class ReelService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  Future<bool> createReel({
    required String title,
    required String description,
    required String category,
    required File videoFile,
    required File thumbnailFile,
    required String link,
    required File? logo,
    required String token,
    bool isPaid = false,
    double price = 0.0,
    bool isSingleImage = false,
  }) async {
    try {
      String fileName = videoFile.path.split(Platform.pathSeparator).last;
      String thumbName = thumbnailFile.path.split(Platform.pathSeparator).last;

      print(
        "📤 [ReelService] Creating Reel: Title='$title', Category='$category'",
      );

      FormData formData = FormData.fromMap({
        'title': title,
        'description': description,
        'category': category,
        'link': link,
        'is_paid': isPaid,
        'price': price,
        'is_single_image': isSingleImage,

        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: fileName,
          contentType: MediaType('video', 'mp4'),
        ),
        'thumbnail': await MultipartFile.fromFile(
          thumbnailFile.path,
          filename: thumbName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      if (logo != null) {
        String logoName = logo.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'logo',
            await MultipartFile.fromFile(
              logo.path,
              filename: logoName,
              contentType: MediaType('image', 'png'),
            ),
          ),
        );
      }

      final response = await _dio.post(
        '${ApiConfig.apiRoot}/reels/create',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print("❌ [ReelService] DioException uploading reel: ${e.message}");
      print("   Status: ${e.response?.statusCode}");
      print("   Data: ${e.response?.data}");
      return false;
    } catch (e) {
      print("❌ [ReelService] Error uploading reel: $e");
      return false;
    }
  }

  Future<bool> toggleLike(String reelId, String token) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiRoot}/reels/$reelId/like',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error toggling like: $e");
      return false;
    }
  }

  Future<bool> toggleSave(String reelId, String token) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiRoot}/reels/$reelId/save',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      // Returns { "saved": true/false }
      return response.statusCode == 200;
    } catch (e) {
      print('Save Error: $e');
      return false;
    }
  }

  Future<List<Comment>> fetchComments(String reelId) async {
    try {
      final response = await _dio.get('${ApiConfig.apiRoot}/reels/$reelId/comments');
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        // Backend returns liked_by array. To determine isLiked, we need current user ID.
        // But ReelService doesn't know user ID easily locally without auth provider context.
        // Ideally backend sets is_liked. 
        // For now, let's map what we have. If backend adds is_liked logic later based on token, fine.
        // Frontend provider can also patch it if we pass user ID.
        return data.map((json) => Comment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Fetch Comments Error: $e');
      return [];
    }
  }

  Future<Comment?> addComment(String reelId, String text, String token) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiRoot}/reels/$reelId/comments',
        data: {'text': text},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return Comment.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Add Comment Error: $e');
       if (e is DioException) {
          print("Response: ${e.response?.data}");
       }
      return null;
    }
  }

  Future<Map<String, dynamic>?> toggleCommentLike(String reelId, String commentId, String token) async {
    try {
        final response = await _dio.post(
            '${ApiConfig.apiRoot}/reels/$reelId/comments/$commentId/like',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (response.statusCode == 200) {
            return response.data; // { success, likes, is_liked }
        }
        return null;
    } catch(e) {
        print("Error toggling comment like: $e");
        return null;
    }
  }

  Future<List<Reel>> fetchReels() async {
    try {
      print(
        '🔄 [ReelService] Fetching reels from: ${ApiConfig.apiRoot}/reels/feed',
      );
      final response = await _dio.get('${ApiConfig.apiRoot}/reels/feed');

      if (response.data == null || response.data is! List) {
        print('⚠️ [ReelService] Invalid response data format');
        return [];
      }

      final List data = response.data;
      print('✅ [ReelService] Fetched ${data.length} reels from backend');

      return data.map((json) {
        // Use the new helper method to construct full URLs
        final videoUrl = json['video_url'] != null
            ? ApiConfig.getFullVideoUrl(json['video_url'])
            : '';
        final thumbnailUrl = json['thumbnail_url'] != null
            ? ApiConfig.getFullVideoUrl(json['thumbnail_url'])
            : null;
        final logoUrl = json['logo_url'] != null
            ? ApiConfig.getFullVideoUrl(json['logo_url'])
            : null;

        print('📹 [ReelService] Reel: ${json['title']} -> Video: $videoUrl');

        return Reel.fromMap({
          ...json,
          'video_url': videoUrl,
          'thumbnail_url': thumbnailUrl,
          'logo_url': logoUrl,
          'app_link': json['app_link'],
          'like_count': json['like_count'] ?? 0,
        });
      }).toList();
    } on DioException catch (e) {
      print('❌ [ReelService] DioException fetching reels: ${e.message}');
      print('   Type: ${e.type}');
      print('   Response: ${e.response?.data}');
      return [];
    } catch (e) {
      print('❌ [ReelService] Error fetching reels: $e');
      return [];
    }
  }

  Future<Map<String, String>?> generateReel({
    required List<File> images,
    required File? audio,
    required File? logo,
    required String title,
    required String link,
    required String? token,
  }) async {
    try {
      FormData formData = FormData();

      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('link', link));

      // Add Images
      for (var image in images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              image.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      // Add Audio
      if (audio != null) {
        formData.files.add(
          MapEntry(
            'audio',
            await MultipartFile.fromFile(
              audio.path,
              contentType: MediaType('audio', 'mpeg'),
            ),
          ),
        );
      }

      // Add Logo
      if (logo != null) {
        formData.files.add(
          MapEntry(
            'logo',
            await MultipartFile.fromFile(
              logo.path,
              contentType: MediaType('image', 'png'),
            ),
          ),
        );
      }

      final response = await _dio.post(
        '${ApiConfig.apiRoot}/reels/generate',
        data: formData,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      print("📥 [ReelService] Generate Resp Status: ${response.statusCode}");
      print("📥 [ReelService] Generate Resp Data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['videoUrl'] != null && data['thumbnailUrl'] != null) {
          return {
            'video': ApiConfig.getFullVideoUrl(data['videoUrl']),
            'thumbnail': ApiConfig.getFullVideoUrl(data['thumbnailUrl']),
          };
        } else {
             throw Exception("Invalid server response: Missing keys. Data: $data");
        }
      } else {
          throw Exception("Server Error: ${response.statusCode} - ${response.data}");
      }
    } on DioException catch (e) {
      print("Error generating reel (Dio): ${e.message}");
      print("Response data: ${e.response?.data}");
      throw Exception("Network Error: ${e.message} \nServer: ${e.response?.data?['message'] ?? e.response?.data}");
    } catch (e) {
      print("Error generating reel: $e");
      throw Exception("Generation Failed: $e");
    }
  }

  Future<List<Reel>> fetchUserReels(String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.apiRoot}/reels/my-reels',
         options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data == null || response.data is! List) return [];
      
      final List data = response.data;
      return data.map((json) {
         final videoUrl = json['video_url'] != null ? ApiConfig.getFullVideoUrl(json['video_url']) : '';
         final thumbnailUrl = json['thumbnail_url'] != null ? ApiConfig.getFullVideoUrl(json['thumbnail_url']) : null;
         final logoUrl = json['logo_url'] != null ? ApiConfig.getFullVideoUrl(json['logo_url']) : null;

         return Reel.fromMap({
          ...json,
          'video_url': videoUrl,
          'thumbnail_url': thumbnailUrl,
          'logo_url': logoUrl,
          'app_link': json['app_link'],
          'like_count': json['like_count'] ?? 0,
        });
      }).toList();
    } catch (e) {
      print("Error fetching user reels: $e");
      return [];
    }
  }

  Future<List<Reel>> searchReels(String query) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.apiRoot}/reels/search', 
        queryParameters: {'q': query},
      );

      if (response.data == null || response.data is! List) return [];

      final List data = response.data;
      return data.map((json) {
         final videoUrl = json['video_url'] != null ? ApiConfig.getFullVideoUrl(json['video_url']) : '';
         final thumbnailUrl = json['thumbnail_url'] != null ? ApiConfig.getFullVideoUrl(json['thumbnail_url']) : null;
         final logoUrl = json['logo_url'] != null ? ApiConfig.getFullVideoUrl(json['logo_url']) : null;

         return Reel.fromMap({
          ...json,
          'video_url': videoUrl,
          'thumbnail_url': thumbnailUrl,
          'logo_url': logoUrl,
          'app_link': json['app_link'],
          'like_count': json['like_count'] ?? 0,
        });
      }).toList();
    } catch (e) {
      print("Error searching reels: $e");
      return [];
    }
  }

  Future<bool> deleteReel(String reelId, String token) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.apiRoot}/reels/$reelId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting reel: $e");
      return false;
    }
  }
  Future<bool> deleteComment(String reelId, String commentId, String token) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.apiRoot}/reels/$reelId/comments/$commentId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting comment: $e");
      return false;
    }
  }
}
