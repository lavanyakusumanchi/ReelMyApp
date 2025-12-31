import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/reel.dart';
import '../../utils/api_config.dart';
import '../../widgets/video_reel_item.dart';
import 'admin_reel_viewer.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool _isLoading = true;
  List<Reel> _userReels = [];

  @override
  void initState() {
    super.initState();
    _fetchUserReels();
  }

  Future<void> _fetchUserReels() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      // 🛡️ Sanitize ID: Remove any timestamp suffix (e.g., _123456)
      String rawId = widget.user['_id'].toString();
      String userId = rawId;
      
      print('🔍 [AdminDetail] Raw User ID: $rawId');

      if (userId.contains('_')) {
        userId = userId.split('_')[0];
      }
      
      // 🛡️ Aggressive Fix: MongoDB ObjectIDs are 24 hex chars. 
      // If we have 25 chars (e.g. trailing '2' or space), truncate it.
      if (userId.length > 24) {
         print('⚠️ [AdminDetail] detailed ID trimming: "${userId}" -> ${userId.substring(0, 24)}');
         userId = userId.substring(0, 24);
      }
      
      print('🔍 [AdminDetail] Final User ID to API: "$userId" (Length: ${userId.length})');

      try {
        final reels = await Provider.of<AdminProvider>(context, listen: false)
            .fetchUserReels(userId, token);
        
        print('✅ [AdminDetail] Fetched ${reels.length} reels');
        
        if (mounted) {
          setState(() {
            _userReels = reels.map((data) => Reel.fromMap(data)).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
         print('❌ [AdminDetail] Error: $e');
         if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _manageUser(String action) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    // 🛡️ Sanitize ID
    String userId = widget.user['_id'].toString();
    if (userId.contains('_')) {
      userId = userId.split('_')[0];
    }

    final admin = Provider.of<AdminProvider>(context, listen: false);
    bool success = await admin.manageUser(userId, action, token);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $action success'),
          backgroundColor: success ? Colors.green : Colors.red,
        )
      );
      if (success) Navigator.pop(context); // Go back after delete
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;
    final isBlocked = user['status'] == 'blocked';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(user['name']),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                   CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      backgroundImage: user['profile_pic'] != null && user['profile_pic'].isNotEmpty
                           ? NetworkImage(ApiConfig.getFullUrl(user['profile_pic']))
                           : null,
                      child: user['profile_pic'] == null || user['profile_pic'].isEmpty 
                          ? Text(user['name'][0].toUpperCase(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primaryColor)) 
                          : null,
                   ),
                   const SizedBox(height: 16),
                   Text(user['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                   Text(user['email'], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                   const SizedBox(height: 16),
                   Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBlocked ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isBlocked ? Colors.red : Colors.green),
                      ),
                      child: Text(
                        isBlocked ? 'Blocked' : 'Active',
                        style: TextStyle(color: isBlocked ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                      ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageUser(isBlocked ? 'unblock' : 'block'),
                    icon: Icon(isBlocked ? Icons.check_circle : Icons.block, color: Colors.white),
                    label: Text(isBlocked ? 'Unblock' : 'Block'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked ? Colors.green : Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _manageUser('delete'),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. User Reels
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'User Reels (${_userReels.length})', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)
              ),
            ),
            const SizedBox(height: 12),
            
            _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _userReels.isEmpty
                    ? Center(child: Text("No reels uploaded.", style: TextStyle(color: Colors.grey[600])))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _userReels.length,
                        itemBuilder: (context, index) {
                          final reel = _userReels[index];
                          return GestureDetector(
                            onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => AdminReelViewer(reel: reel),
                                 ),
                               );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                image: reel.thumbnailUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(ApiConfig.getFullUrl(reel.thumbnailUrl!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                     reel.thumbnailUrl == null
                                      ? const Center(child: Icon(Icons.play_circle_outline, color: Colors.white))
                                      : const SizedBox.shrink(),
                                     // View Count Overlay
                                     Positioned(
                                       bottom: 4,
                                       left: 4,
                                       child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: Colors.black54,
                                           borderRadius: BorderRadius.circular(4),
                                         ),
                                         child: Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                              const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${reel.views}', 
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                              ),
                                           ],
                                         ),
                                       ),
                                     ),
                                  ],
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
