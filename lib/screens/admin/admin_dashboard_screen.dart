import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_config.dart';
import 'admin_reel_viewer.dart';
import '../../models/reel.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllReels; // Callback for navigation
  final VoidCallback? onViewUsers;

  const AdminDashboardScreen({super.key, this.onViewAllReels, this.onViewUsers});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<AdminProvider>(context, listen: false).fetchStats(token);
        Provider.of<AdminProvider>(context, listen: false).fetchReels(token); // For recent list
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final stats = admin.stats;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic BG
      body: admin.isLoading && stats == null
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.canvasColor,
              onRefresh: () async {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                if (token != null) {
                   await admin.fetchStats(token);
                   await admin.fetchReels(token);
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(stats, isDark),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          'Recent Reels',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (widget.onViewAllReels != null)
                          TextButton(
                            onPressed: widget.onViewAllReels,
                            child: Row(
                              children: [
                                Text('View All', style: TextStyle(color: theme.primaryColor)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 12, color: theme.primaryColor)
                              ],
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentReels(admin.reels, isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users', 
          stats?['totalUsers']?.toString() ?? '0', 
          Icons.people, 
          const [Color(0xFF00D9FF), Color(0xFF0099CC)], // Cyan Gradient
          isDark,
          onTap: widget.onViewUsers,
        ),
        _buildStatCard(
          'Total Reels', 
          stats?['totalReels']?.toString() ?? '0', 
          Icons.movie_creation, 
          const [Color(0xFF7C3AED), Color(0xFF5B21B6)], // Purple Gradient
          isDark,
          onTap: widget.onViewAllReels,
        ),
        _buildStatCard(
          'Total Views', 
          stats?['totalViews']?.toString() ?? '0', 
          Icons.visibility, 
          const [Color(0xFFF59E0B), Color(0xFFD97706)], // Orange Gradient
          isDark
        ),
         _buildStatCard(
          'Active Today', 
          stats?['activeToday']?.toString() ?? '0', 
          Icons.show_chart, 
          const [Color(0xFF10B981), Color(0xFF059669)], // Green Gradient
          isDark
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, List<Color> gradientColors, bool isDark, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A3E) : Colors.white, // Card BG
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 5))
            ]
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReels(List<dynamic> reels, bool isDark) {
    final recent = reels.take(5).toList(); // Show top 5
    if (recent.isEmpty) {
        return Center(child: Text("No reels found", style: TextStyle(color: Colors.grey[600])));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final reel = recent[index];
        final logoUrl = reel['logo_url'];
        final thumbUrl = reel['thumbnail_url'];
        String displayImage = '';
        bool isValid(String? s) => s != null && s.isNotEmpty;
        
        if (isValid(logoUrl)) displayImage = ApiConfig.getFullUrl(logoUrl);
        else if (isValid(thumbUrl)) displayImage = ApiConfig.getFullUrl(thumbUrl);

        return Card(
          color: isDark ? const Color(0xFF1E2230) : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isDark ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              print("AdminDashboard: Tapped on recent reel ${reel['_id']}");
              try {
                 final reelObj = Reel.fromMap(reel);
                 Navigator.of(context).push(
                   MaterialPageRoute(builder: (_) => AdminReelViewer(reel: reelObj))
                 );
              } catch (e) {
                 print("Error creating reel: $e");
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not play reel: $e")));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: displayImage.isNotEmpty
                      ? Image.network(
                          displayImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey),
                        )
                      : Container(
                        width: 50, 
                        height: 50, 
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        child: Icon(Icons.image, size: 20, color: isDark ? Colors.white54 : Colors.grey[600]),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel['title'] ?? 'Untitled',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'By ${reel['user']?['name'] ?? 'Unknown'}',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reel['status'] == 'active' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    reel['status']?.toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: reel['status'] == 'active' ? Colors.green : Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
