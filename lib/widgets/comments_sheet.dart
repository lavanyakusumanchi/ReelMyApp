import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/comment.dart';
import '../providers/reel_provider.dart';
import '../providers/auth_provider.dart';

class CommentsSheet extends StatefulWidget {
  final String reelId;
  final List<Comment> comments;
  final VoidCallback onClose;

  const CommentsSheet({
    super.key,
    required this.reelId,
    required this.comments,
    required this.onClose,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              'Comments',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Comments List
          Expanded(
            child: Consumer<ReelProvider>(
              builder: (context, provider, child) {
                final comments = provider.getCommentsForReel(widget.reelId);
                return comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        // itemCount: comments.length,
                        // Fix for visibility: Ensure keyboard doesn't hide last item?
                        // Actually, just ensuring it builds correctly.
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentItem(comment);
                        },
                      );
              },
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    // Check if current user is owner
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user != null ? auth.user!['_id'] : null;
    final isMyComment = currentUserId != null && currentUserId == comment.userId;
    
    // Ideally check reel owner too, but we need reel object to know owner. 
    // Comment model doesn't store reel owner ID. 
    // ReelProvider has reels, we can lookup.
    final reel = context.read<ReelProvider>().getReel(widget.reelId);
    final isReelOwner = reel != null && reel.userId != null && reel.userId == currentUserId;

    final canDelete = isMyComment || isReelOwner;

    return GestureDetector(
      onLongPress: () {
        if (canDelete) {
          _showDeleteDialog(comment);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.blueAccent,
              child: Text(
                  comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName, // Actual Name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _formatTime(comment.createdAt), // Simple formatter
                        style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    comment.text,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () {
                        // Reply Action: specific to this comment
                        _commentController.text = "@${comment.userName} ";
                        _focusNode.requestFocus();
                        _commentController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _commentController.text.length)
                        );
                    },
                    child: Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Like Button
            Column(
                children: [
                    GestureDetector(
                      onTap: () async {
                         final storage = const FlutterSecureStorage();
                         final token = await storage.read(key: 'token');
                         if (token != null && mounted) {
                             context.read<ReelProvider>().toggleCommentLike(widget.reelId, comment.id, token);
                         }
                      },
                      child: Icon(
                          comment.isLiked ? Icons.favorite : Icons.favorite_border, 
                          color: comment.isLiked ? Colors.red : Colors.white54, 
                          size: 16.sp
                      ),
                    ),
                    if (comment.likes > 0)
                        Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(
                                '${comment.likes}',
                                style: TextStyle(color: Colors.white54, fontSize: 10.sp),
                            ),
                        )
                ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF262626),
        title: const Text("Delete Comment?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this comment?", 
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
             child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
                Navigator.pop(ctx); // Close dialog
                final storage = const FlutterSecureStorage();
                final token = await storage.read(key: 'token');
                if (token != null && mounted) {
                    await context.read<ReelProvider>().deleteComment(widget.reelId, comment.id, token);
                }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'now';
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      // Get token (in real app, use auth provider or secure storage)
      // For now, simpler to read directly here or assume provider has it?
      // Better: pass token or handle in provider. Provider doesn't store token usually.
      // Let's read storage here.
      
      final storage = const FlutterSecureStorage(); 
      final token = await storage.read(key: 'token');

      if (token != null && mounted) {
        Provider.of<ReelProvider>(
            context,
            listen: false,
        ).addComment(widget.reelId, text, token);
      }
      
      _commentController.clear();
      // Optional: hide keyboard
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        8.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: Colors.purpleAccent,
            child: Icon(Icons.person, color: Colors.white, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14.sp),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          TextButton(
            onPressed: _postComment,
            child: const Text(
              'Post',
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
