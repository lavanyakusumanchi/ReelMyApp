import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../utils/api_config.dart';

class ChatProvider with ChangeNotifier {
  final Dio _dio = Dio();
  
  List<Chat> _chats = [];
  List<Chat> get chats => _chats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Cache messages for current chat
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  Future<void> fetchChats(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _dio.get(
        '${ApiConfig.apiRoot}/chats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final data = response.data as List;
      _chats = data.map((e) => Chat.fromJson(e)).toList();
      
    } catch (e) {
      print("Fetch Chats Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String chatId, String token) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.apiRoot}/chats/$chatId/messages',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final data = response.data as List;
      _messages = data.map((e) => Message.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
       print("Fetch Messages Error: $e");
    }
  }

  Future<Message?> sendMessage(String recipientId, String content, String token) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.apiRoot}/chats/message',
        data: {
          'recipientId': recipientId,
          'content': content,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      final newMessage = Message.fromJson(response.data);
      _messages.add(newMessage);
      notifyListeners();
      
      // Refresh chat list to update last message
      fetchChats(token); 
      
      return newMessage;
    } catch (e) {
      print("Send Message Error: $e");
      return null;
    }
  }

    // Search users to start new chat
  Future<List<Map<String, dynamic>>> searchUsers(String query, String token) async {
    if (query.isEmpty) return [];
    try {
       final response = await _dio.get(
        '${ApiConfig.apiRoot}/chats/users/search',
        queryParameters: {'q': query},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch(e) {
      print("Search Users Error: $e");
      return [];
    }
  }
  
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
