import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/reel.dart';
import '../theme/app_colors.dart';

class AppStoreBottomSheet extends StatelessWidget {
  final Reel reel;

  const AppStoreBottomSheet({super.key, required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon, Title, Dev
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          image: reel.logoUrl != null && reel.logoUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(reel.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: reel.logoUrl == null || reel.logoUrl!.isEmpty
                            ? const Icon(Icons.apps, color: Colors.white54, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reel.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reel.category, // Using category as Developer Name
                              style: TextStyle(
                                color: AppColors.neonCyan,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Contains ads • In-app purchases",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("4.4 ★", "17Cr reviews"),
                      _buildDivider(),
                      _buildStat("87 MB", ""),
                      _buildDivider(),
                      _buildStat("12+", "Rated for 12+"),
                      _buildDivider(),
                      _buildStat("10M+", "Downloads"),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Install Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (reel.appLink != null) {
                           final uri = Uri.parse(reel.appLink!);
                           if (await canLaunchUrl(uri)) {
                             launchUrl(uri, mode: LaunchMode.externalApplication);
                           }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonBlue, // Standard Blue like Play Store
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Install",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Screenshots / About
                  Text(
                    "About this app",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reel.description.isNotEmpty 
                        ? reel.description 
                        : "A little connection can go a long way. Connect with friends and the world around you on ${reel.title}.",
                   style: const TextStyle(color: Colors.grey, height: 1.4),
                   maxLines: 3,
                   overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 20),

                  // Screenshots List (Mocked)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                         // Use thumbnail or placeholders
                         return Container(
                           width: 120,
                           margin: const EdgeInsets.only(right: 12),
                           decoration: BoxDecoration(
                             color: Colors.grey[900],
                             borderRadius: BorderRadius.circular(12),
                             image: reel.thumbnailUrl != null
                                 ? DecorationImage(
                                     image: NetworkImage(reel.thumbnailUrl!), 
                                     fit: BoxFit.cover,
                                     opacity: 0.7, // Dim it slightly 
                                   )
                                 : null,
                           ),
                           child: Center(
                             child: Icon(Icons.image, color: Colors.white24),
                           ),
                         );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String top, String bottom) {
      return Column(
        children: [
           Text(top, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
           if (bottom.isNotEmpty)
             Text(bottom, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      );
  }
  
  Widget _buildDivider() => Container(height: 20, width: 1, color: Colors.grey[800]);

}
