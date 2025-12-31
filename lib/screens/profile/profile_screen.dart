import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reel_provider.dart';
import '../../models/reel.dart';
import '../../widgets/video_reel_item.dart';
import '../../utils/api_config.dart';
import '../../utils/app_localizations.dart'; // NEW
import '../settings/settings_screen.dart';

import 'package:reel_my_apps/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final reelProvider = Provider.of<ReelProvider>(context, listen: false);
      auth.fetchProfile();
      // Ensure saved reels are fresh
      auth.fetchSavedReels();
      
      // Fetch User Reels
      _fetchUserReels(reelProvider);
    });
  }

  Future<void> _fetchUserReels(ReelProvider reelProvider) async {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');
      if (token != null) {
          await reelProvider.fetchUserReels(token);
      }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final reelProvider = Provider.of<ReelProvider>(context);
    final user = auth.user;
    final savedReels = auth.savedReels; 
    final myReels = reelProvider.userReels;
    
    // Localization Helper
    String t(String key) => AppLocalizations.of(context).translate(key);

    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: auth.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : (user == null)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(auth.errorMessage ?? "Failed to load profile", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                         final auth = Provider.of<AuthProvider>(context, listen: false);
                         auth.fetchProfile();
                         _fetchUserReels(Provider.of<ReelProvider>(context, listen: false));
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
          : Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Column(
                  children: [
                     // Custom AppBar
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                       child: Row(
                         children: [
                           IconButton(
                             icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                             onPressed: () => Navigator.pop(context),
                           ),
                           const SizedBox(width: 10),
                           Text(t('profile'), style: Theme.of(context).textTheme.headlineSmall),
                           const Spacer(),
                           IconButton(
                             icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
                             onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                             },
                           )
                         ],
                       ),
                     ),

                     // Avatar Area
                     const SizedBox(height: 10),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2), // Border width
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blueAccent, // Border color
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Theme.of(context).cardColor,
                                backgroundImage: (user['profile_pic'] != null && user['profile_pic'].isNotEmpty)
                                    ? NetworkImage(ApiConfig.getFullVideoUrl(user['profile_pic']))
                                    : null,
                                child: (user['profile_pic'] == null || user['profile_pic'].isEmpty)
                                    ? Icon(Icons.person, size: 50, color: Theme.of(context).iconTheme.color?.withOpacity(0.5))
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0, 
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                     const SizedBox(height: 12),
                     Text(user['name'] ?? "Unknown", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     Text(user['email'] ?? "", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
                     
                     const SizedBox(height: 10),
                     Text("${t('reels')}: ${user['reel_count'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(height: 10),
                     
                     // Tab Bar
                     TabBar(
                       indicatorColor: Colors.blueAccent,
                       labelColor: Colors.blueAccent,
                       unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                       tabs: [
                         Tab(text: t('my_reels'), icon: const Icon(Icons.video_collection)),
                         Tab(text: t('saved'), icon: const Icon(Icons.bookmark)),
                       ],
                     ),

                     // Tab View
                     Expanded(
                       child: TabBarView(
                         children: [
                           // My Reels Tab
                           _buildMyReelsTab(context, myReels),

                           // Saved Reels Tab
                           _buildSavedReelsTab(context, savedReels),
                         ],
                       ),
                     ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildMyReelsTab(BuildContext context, List<dynamic> reels) {
      if (reels.isEmpty) {
          return const Center(child: Text("You haven't created any reels yet.", style: TextStyle(color: Colors.white54)));
      }
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: reels.length,
        itemBuilder: (context, index) {
          final reel = reels[index];
          // reel is an object of type Reel here
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () async {
                     // Navigate to player
                     await Navigator.push(context, MaterialPageRoute(builder: (_) => _SingleReelPlayer(reel: reel)));
                     // Refresh on return
                     if (context.mounted) {
                        _fetchUserReels(Provider.of<ReelProvider>(context, listen: false));
                     }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    image: reel.thumbnailUrl != null ? DecorationImage(
                      image: NetworkImage(reel.thumbnailUrl!),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: reel.thumbnailUrl == null ? const Icon(Icons.movie, color: Colors.white54) : null,
                ),
              ),
              Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                      onTap: () => _confirmDelete(context, reel),
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                      ),
                  ),
              ),
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
          );
        },
      );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic reel) async {
       final confirm = await showDialog<bool>(
            context: context, 
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              title: const Text("Delete Reel", style: TextStyle(color: Colors.white)),
              content: const Text("Are you sure you want to delete this reel? This cannot be undone.", style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => Navigator.pop(ctx, true), 
                    child: const Text("Delete")
                ),
              ],
            )
       );

       if (confirm == true && context.mounted) {
           final storage = const FlutterSecureStorage();
           final token = await storage.read(key: 'token');
           
           if (token != null && context.mounted) {
                await Provider.of<ReelProvider>(context, listen: false).deleteReel(reel.id, token);
           }
       }
  }

  Widget _buildSavedReelsTab(BuildContext context, List<dynamic> savedReels) {
    if (savedReels.isEmpty) {
      return const Center(child: Text("No saved reels yet.", style: TextStyle(color: Colors.white54)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: savedReels.length,
      itemBuilder: (context, index) {
        final reelMap = savedReels[index];
        final thumb = reelMap['thumbnail_url'];
        final fullThumb = thumb != null ? ApiConfig.getFullVideoUrl(thumb) : null;
        
        return GestureDetector(
          onTap: () async {
               try {
                   // Helper to get full URL if not absolute
                   String getUrl(String? u) => u != null ? ApiConfig.getFullVideoUrl(u) : '';
                   
                   final reelObj = Reel.fromMap({
                       ...reelMap,
                       'video_url': getUrl(reelMap['video_url']),
                       'thumbnail_url': getUrl(reelMap['thumbnail_url']),
                       'logo_url': getUrl(reelMap['logo_url']),
                       'is_saved': true, // Assuming it IS saved if here
                   });
                   
                   await Navigator.push(context, MaterialPageRoute(builder: (_) => _SingleReelPlayer(reel: reelObj)));
                   
                   // Refresh saved list when returning, in case user unsaved it
                   if (context.mounted) {
                      Provider.of<AuthProvider>(context, listen: false).fetchSavedReels();
                   }
               } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot play this reel")));
                   print("Error parsing saved reel: $e");
               }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              image: fullThumb != null ? DecorationImage(
                image: NetworkImage(fullThumb),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: fullThumb == null ? const Icon(Icons.movie, color: Colors.white54) : null,
          ),
        );
      },
    );
  }
}

class _SingleReelPlayer extends StatelessWidget {
  final dynamic reel; // Reel object
  const _SingleReelPlayer({required this.reel});

  @override
  Widget build(BuildContext context) {
    // Import VideoReelItem locally or ensure it's imported at top
    // It seems missing from imports in profile_screen.dart
    return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
        ),
        body: Center(
            // We need to import VideoReelItem. 
            // Since this tool replaces content, I should also check imports.
            // But I can't check imports in this same block easily without replacing whole file.
            // I'll assume I need to fix imports in a separate step or try to use a basic player if import fails.
            // But VideoReelItem is complex. I MUST import it.
            // I'll add the class here, and then add the import at the top in next step.
           child: VideoReelItem(reel: reel, isVisible: true), 
        ),
    );
  }
}
