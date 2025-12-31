import 'package:flutter/material.dart';
import '../models/reel.dart';
import '../models/comment.dart';
import '../services/reel_service.dart';

// Using the Reel model from models/reel.dart

class ReelProvider with ChangeNotifier {
  final ReelService _reelService = ReelService();
  String _selectedCategory = 'All';

  String get selectedCategory => _selectedCategory;

  
  


  List<Reel> _reels = [];

  ReelProvider() {
    fetchReels();
  }

  Future<void> fetchReels() async {
    final backendReels = await _reelService.fetchReels();
    final uniqueReels = <String, Reel>{};
    for (var reel in backendReels) {
      uniqueReels[reel.id] = reel;
    }
    final list = uniqueReels.values.toList();
    list.shuffle(); // Randomize order on refresh
    _reels = list;
    notifyListeners();
  }


  List<Reel> get reels => _reels;

  // Helper to find existing reel reference
  Reel? getReel(String id) {
    try {
      return _reels.firstWhere((r) => r.id == id);
    } catch (_) {
      try {
        return _userReels.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  List<Reel> get filteredReels {
    if (_selectedCategory == 'All') {
      return _reels;
    }
    return _reels.where((r) => r.category == _selectedCategory).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  final Map<String, List<Comment>> _comments = {};

  Future<void> fetchComments(String reelId) async {
    final comments = await _reelService.fetchComments(reelId);
    _comments[reelId] = comments;
    notifyListeners();
  }

  List<Comment> getCommentsForReel(String reelId) {
    if (!_comments.containsKey(reelId)) {
        fetchComments(reelId);
    }
    return _comments[reelId] ?? [];
  }

  Future<void> toggleLike(String reelId, String? token) async {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      // Optimistic update
      _reels[index] = Reel(
        id: reel.id,
        videoUrl: reel.videoUrl,
        title: reel.title,
        description: reel.description,
        category: reel.category,
        appLink: reel.appLink,
        likes: reel.isLiked ? reel.likes - 1 : reel.likes + 1,
        comments: reel.comments,
        createdAt: reel.createdAt,
        isLiked: !reel.isLiked,
        isSaved: reel.isSaved,
        logoUrl: reel.logoUrl,
        thumbnailUrl: reel.thumbnailUrl,
      );
      notifyListeners();

      // Persist to backend
      if (token != null) {
        final success = await _reelService.toggleLike(reelId, token);
        if (!success) {
          // Revert if failed
           _reels[index] = reel; 
           notifyListeners();
        }
      }
    }
  }

  Future<bool> toggleSave(String reelId, String? token) async {
    final index = _reels.indexWhere((r) => r.id == reelId);
    if (index != -1) {
      final reel = _reels[index];
      // Optimistic Update
      _reels[index] = Reel(
        id: reel.id,
        videoUrl: reel.videoUrl,
        title: reel.title,
        description: reel.description,
        category: reel.category,
        appLink: reel.appLink,
        likes: reel.likes,
        comments: reel.comments,
        createdAt: reel.createdAt,
        isLiked: reel.isLiked,
        isSaved: !reel.isSaved, // Toggle
        logoUrl: reel.logoUrl,
        thumbnailUrl: reel.thumbnailUrl,
      );
      notifyListeners();

      if (token != null) {
        final success = await _reelService.toggleSave(reelId, token);
        if (!success) {
            // Revert
            final revertIndex = _reels.indexWhere((r) => r.id == reelId); // Re-find index
            if (revertIndex != -1) {
               _reels[revertIndex] = reel; 
               notifyListeners();
            }
            return false;
        }
        return true;
      }
    } else {
        // Also check if it is in User Reels but not Main Feed
        final uIndex = _userReels.indexWhere((r) => r.id == reelId);
        if (uIndex != -1) {
             final uReel = _userReels[uIndex];
             _userReels[uIndex] = Reel(
                id: uReel.id,
                videoUrl: uReel.videoUrl,
                title: uReel.title,
                description: uReel.description,
                category: uReel.category,
                appLink: uReel.appLink,
                likes: uReel.likes,
                comments: uReel.comments,
                createdAt: uReel.createdAt,
                isLiked: uReel.isLiked,
                isSaved: !uReel.isSaved, // Toggle
                logoUrl: uReel.logoUrl,
                thumbnailUrl: uReel.thumbnailUrl,
             );
             notifyListeners();
             
             if (token != null) {
                 final success = await _reelService.toggleSave(reelId, token);
                 if (!success) {
                     // Revert
                     final rIndex = _userReels.indexWhere((r) => r.id == reelId);
                     if (rIndex != -1) {
                         _userReels[rIndex] = uReel;
                         notifyListeners();
                     }
                     return false;
                 }
                 return true;
             }
        }
    }
    return false;
  }

  void addReel(Reel reel) {
    _reels.insert(0, reel);
    notifyListeners();
  }

  Future<void> addComment(String reelId, String text, String token) async {
    // Optimistic Update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempComment = Comment(
      id: tempId,
      reelId: reelId,
      userId: 'pending', 
      text: text,
      createdAt: DateTime.now(),
      userName: 'You', // Assuming local display
    );

    if (_comments.containsKey(reelId)) {
        _comments[reelId]!.insert(0, tempComment);
    } else {
        _comments[reelId] = [tempComment];
    }
    notifyListeners();

    print("📝 [ReelProvider] Adding comment: $text");

    // Actual Backend Call
    final newComment = await _reelService.addComment(reelId, text, token);
    
    if (newComment != null) {
        print("✅ [ReelProvider] Comment added successfully: ${newComment.id}");
        // Replace temp with real
        final list = _comments[reelId]!;
        final index = list.indexWhere((c) => c.id == tempId);
        if (index != -1) {
            list[index] = newComment;
        }
        
        // Update count
        final reelIndex = _reels.indexWhere((r) => r.id == reelId);
        if (reelIndex != -1) {
            final reel = _reels[reelIndex];
            _reels[reelIndex] = Reel(
                 id: reel.id,
                videoUrl: reel.videoUrl,
                title: reel.title,
                description: reel.description,
                category: reel.category,
                appLink: reel.appLink,
                likes: reel.likes,
                comments: reel.comments + 1,
                createdAt: reel.createdAt,
                isLiked: reel.isLiked,
                isSaved: reel.isSaved,
                logoUrl: reel.logoUrl,
                thumbnailUrl: reel.thumbnailUrl,
            );
        }
        notifyListeners();
    } else {
        print("❌ [ReelProvider] Failed to add comment. Removing temp.");
        // Failed, remove temp
        _comments[reelId]?.removeWhere((c) => c.id == tempId);
        notifyListeners();
    }
  }

  Future<void> toggleCommentLike(String reelId, String commentId, String token) async {
      // Optimistic Update
      if (_comments.containsKey(reelId)) {
          final list = _comments[reelId]!;
          final index = list.indexWhere((c) => c.id == commentId);
          if (index != -1) {
              final oldComment = list[index];
              final newIsLiked = !oldComment.isLiked;
              final newLikes = newIsLiked ? oldComment.likes + 1 : (oldComment.likes > 0 ? oldComment.likes - 1 : 0);
              
              list[index] = Comment(
                  id: oldComment.id, 
                  reelId: oldComment.reelId, 
                  userId: oldComment.userId, 
                  text: oldComment.text, 
                  createdAt: oldComment.createdAt,
                  userName: oldComment.userName,
                  likes: newLikes,
                  isLiked: newIsLiked
              );
              notifyListeners();

              final result = await _reelService.toggleCommentLike(reelId, commentId, token);
              if (result == null) {
                  // Revert
                  list[index] = oldComment; 
                  notifyListeners();
              } else {
                  // Update with actual server values to be safe
                   list[index] = Comment(
                      id: oldComment.id, 
                      reelId: oldComment.reelId, 
                      userId: oldComment.userId, 
                      text: oldComment.text, 
                      createdAt: oldComment.createdAt,
                      userName: oldComment.userName,
                      likes: result['likes'],
                      isLiked: result['is_liked']
                  );
                  notifyListeners();
              }
          }
      }
  }

  Future<void> deleteComment(String reelId, String commentId, String token) async {
      if (_comments.containsKey(reelId)) {
           final list = _comments[reelId]!;
           final index = list.indexWhere((c) => c.id == commentId);
           if (index != -1) {
               final removed = list.removeAt(index);
               
               // Update reel comment count optimistically
               final reelIndex = _reels.indexWhere((r) => r.id == reelId);
               if (reelIndex != -1) {
                   final r = _reels[reelIndex];
                   _reels[reelIndex] = Reel(
                       id: r.id, videoUrl: r.videoUrl, title: r.title, description: r.description, category: r.category, appLink: r.appLink, likes: r.likes, 
                       comments: r.comments > 0 ? r.comments - 1 : 0, 
                       createdAt: r.createdAt, isLiked: r.isLiked, isSaved: r.isSaved, logoUrl: r.logoUrl, thumbnailUrl: r.thumbnailUrl
                   );
               }
               
               notifyListeners();

               final success = await _reelService.deleteComment(reelId, commentId, token);
               if (!success) {
                   // Revert
                   list.insert(index, removed);
                   // Revert count
                    if (reelIndex != -1) {
                       final r = _reels[reelIndex];
                        _reels[reelIndex] = Reel(
                           id: r.id, videoUrl: r.videoUrl, title: r.title, description: r.description, category: r.category, appLink: r.appLink, likes: r.likes, 
                           comments: r.comments + 1, 
                           createdAt: r.createdAt, isLiked: r.isLiked, isSaved: r.isSaved, logoUrl: r.logoUrl, thumbnailUrl: r.thumbnailUrl
                       );
                   }
                   notifyListeners();
               }
           }
      }
  }
  // --- User Reels Management ---
  List<Reel> _userReels = [];
  List<Reel> get userReels => _userReels;

  Future<void> fetchUserReels(String token) async {
    _userReels = await _reelService.fetchUserReels(token);
    notifyListeners();
  }

  Future<bool> deleteReel(String reelId, String token) async {
    final success = await _reelService.deleteReel(reelId, token);
    if (success) {
      _userReels.removeWhere((r) => r.id == reelId);
      // Also remove from main feed if present
      _reels.removeWhere((r) => r.id == reelId);
      notifyListeners();
    }
    return success;
  }
  // Sync external reel state (e.g. from Profile) into Provider
  void syncReelState(Reel updatedReel) {
    // 1. Update in Main Feed
    final index = _reels.indexWhere((r) => r.id == updatedReel.id);
    if (index != -1) {
      _reels[index] = updatedReel;
      notifyListeners();
    }
    
    // 2. Update in User Reels
    final userIndex = _userReels.indexWhere((r) => r.id == updatedReel.id);
    if (userIndex != -1) {
      _userReels[userIndex] = updatedReel;
      notifyListeners();
    }
  }
  
  // Search Reels
  Future<List<Reel>> searchReels(String query) async {
      return await _reelService.searchReels(query);
  }
}
