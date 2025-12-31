import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_config.dart';
import 'admin_reel_viewer.dart';
import '../../models/reel.dart';

class AdminReelsScreen extends StatefulWidget {
  const AdminReelsScreen({super.key});

  @override
  State<AdminReelsScreen> createState() => _AdminReelsScreenState();
}

class _AdminReelsScreenState extends State<AdminReelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All Reels'; // 'All Reels', 'Active', 'Pending Review'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReels();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadReels() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<AdminProvider>(context, listen: false).fetchReels(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter Logic
    final filteredReels = admin.reels.where((reel) {
       final title = (reel['title'] ?? '').toString().toLowerCase();
       final userName = (reel['user']?['name'] ?? '').toString().toLowerCase();
       final matchesSearch = title.contains(_searchQuery) || userName.contains(_searchQuery);
       
       if (!matchesSearch) return false;

       if (_filterStatus == 'Active') return reel['status'] == 'active';
       if (_filterStatus == 'Pending Review') return reel['status'] == 'pending';
       return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
           // Search Bar
           Padding(
             padding: const EdgeInsets.all(16),
             child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A3E) : Colors.grey[200], // Search BG
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? const Color(0xFF1F2937) : Colors.transparent),
                ),
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search reels...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                  ),
                ),
             ),
           ),

           // Filter Chips
           SingleChildScrollView(
             scrollDirection: Axis.horizontal,
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: Row(
               children: [
                 _buildFilterChip('All Reels', theme),
                 const SizedBox(width: 8),
                 _buildFilterChip('Active', theme),
                 const SizedBox(width: 8),
                 _buildFilterChip('Pending Review', theme),
               ],
             ),
           ),
           const SizedBox(height: 16),

           // List
           Expanded(
             child: admin.isLoading && admin.reels.isEmpty 
               ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
               : RefreshIndicator(
                   color: theme.primaryColor,
                   backgroundColor: theme.canvasColor,
                   onRefresh: _loadReels,
                   child: ListView.builder(
                     padding: const EdgeInsets.symmetric(horizontal: 16),
                     itemCount: filteredReels.length,
                     itemBuilder: (context, index) {
                       return _buildReelCard(filteredReels[index], isDark);
                     },
                   ),
                 ),
           )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _filterStatus == label;
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : (isDark ? const Color(0xFF1A1A3E) : Colors.white), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? theme.primaryColor : (isDark ? Colors.white10 : Colors.grey[300]!)),
          boxShadow: isSelected ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))
          ]
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
            fontWeight: FontWeight.bold,
            fontSize: 13
          ),
        ),
      ),
    );
  }

  void _manageReel(String? inputId, String action) async {
    if (inputId == null || inputId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Invalid Reel ID')));
        return;
    }
    String reelId = inputId; // Safe now

    // 🛡️ Sanitize ID
    String cleanId = reelId.trim().replaceAll(RegExp(r'[^0-9a-fA-F]'), ''); // Keep ONLY hex chars
    
    // Aggressive Fix: MongoDB ObjectIDs are 24 chars
    if (cleanId.length > 24) {
      cleanId = cleanId.substring(0, 24);
    }
    
    if (cleanId.length != 24) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aborting: ID corrupted ($cleanId)')));
       print("❌ [AdminReels] ID Validation Failed: '$cleanId' (Length: ${cleanId.length})");
       return;
    }
    
    // Show Confirmation Code
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Reel?'),
        content: Text('Are you sure you want to $action this reel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: action == 'delete' ? Colors.red : Colors.blue),
            child: const Text('Confirm'),
          )
        ],
      )
    );

    if (confirm != true) return;

    // Show Loading
    if (!mounted) return;
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    bool success = false;
    String? errorMsg;

    if (token != null) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      success = await provider.manageReel(cleanId, action, token);
      errorMsg = provider.error;
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    // Show Result
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reel $action success!'), backgroundColor: Colors.green)
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to $action reel.\nError: ${errorMsg ?? "Unknown"}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        )
      );
    }
  }

  Widget _buildReelCard(dynamic reel, bool isDark) {
    // Data Parsing
    final status = reel['status'] ?? 'active';
    Color statusColor = status == 'active'
        ? const Color(0xFF10B981)
        : (status == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));

    final user = reel['user'] ?? {};
    final handle = '@${(user['name'] ?? 'User').toString().replaceAll(' ', '').toLowerCase()}';
    
    // 🛠️ Robust ID retrieval (Backend might send id or _id)
    final rawId = reel['_id'] ?? reel['id'];
    final reelId = rawId?.toString() ?? '';
    if (reelId.isEmpty) print("⚠️ [ReelCard] Warning: Reel ID is empty for ${reel['title']}");

    // 1. Image Logic
    final logoUrl = reel['logo_url'];
    final thumbUrl = reel['thumbnail_url'];
    bool isValid(String? s) => s != null && s.isNotEmpty;
    String displayImage = '';
    if (isValid(logoUrl)) {
      displayImage = ApiConfig.getFullUrl(logoUrl);
    } else if (isValid(thumbUrl)) {
      displayImage = ApiConfig.getFullUrl(thumbUrl);
    }

    // 2. Time Logic
    String timeDisplay = 'Just now';
    if (reel['created_at'] != null) {
      try {
        final date = DateTime.parse(reel['created_at']);
        timeDisplay = timeago.format(date);
      } catch (e) {
        timeDisplay = 'Recently';
      }
    }

    return Card(
      color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          print("AdminReelsScreen: Tapped on reel ${reel['_id']}");
          try {
            final reelObj = Reel.fromMap(reel);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AdminReelViewer(reel: reelObj)),
            );
          } catch (e, stack) {
            print("Error opening reel viewer: $e");
            print(stack);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Could not play reel: $e")),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: displayImage.isNotEmpty
                    ? Image.network(
                        displayImage,
                        width: 80,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/logo_v6.png',
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/logo_v6.png',
                        width: 80,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reel['title'] ?? 'Untitled',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: isDark ? const Color(0xFF2A2E3D) : Colors.white,
                            dividerColor: isDark ? Colors.white10 : Colors.grey[200],
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (action) => _manageReel(reelId, action),
                            itemBuilder: (context) => [
                              if (status != 'active')
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: Row(children: [
                                    Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Text('Approve'),
                                  ]),
                                ),
                              if (status != 'rejected')
                                const PopupMenuItem(
                                  value: 'reject',
                                  child: Row(children: [
                                    Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Reject'),
                                  ]),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user['name']} • $timeDisplay',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                    ),
                    Text(handle, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
                    const SizedBox(height: 12),
                    // Stats Row
                    Row(
                      children: [
                        _buildStat(Icons.visibility_outlined, reel['view_count'] ?? 0),
                        const SizedBox(width: 16),
                        _buildStat(Icons.thumb_up_alt_outlined, reel['like_count'] ?? 0),
                        const SizedBox(width: 16),
                        _buildStat(Icons.mode_comment_outlined, reel['comment_count'] ?? 0),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        status == 'pending'
                            ? 'Pending Review'
                            : status.toString().toUpperCase().substring(0, 1) + status.toString().substring(1),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 14),
        const SizedBox(width: 4),
        Text(count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
