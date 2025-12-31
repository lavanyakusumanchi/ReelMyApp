import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../utils/api_config.dart';
import '../utils/app_localizations.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final name = user?['name'] ?? "User";
    final email = user?['email'] ?? "";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "U";
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent, 
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1F1F), Color(0xFF000000)], // Premium Dark
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Close Button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. User Profile
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 10)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          backgroundImage: (user?['profile_pic'] != null && user!['profile_pic'].isNotEmpty)
                              ? NetworkImage(ApiConfig.getFullVideoUrl(user['profile_pic'])) 
                              : null,
                          child: (user?['profile_pic'] == null || user!['profile_pic'].isEmpty)
                              ? Text(initial, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email,
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 3. Menu Items
                _buildMenuItem(context, Icons.person_outline, t.translate('profile'), onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                }),

                _buildMenuItem(context, Icons.settings_outlined, t.translate('settings'), onTap: () {
                   Navigator.pop(context);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),

                const Spacer(),
                _buildMenuItem(context, Icons.logout, t.translate('logout'), isLogout: true, onTap: () {
                   Navigator.pop(context); // Close drawer
                   Provider.of<AuthProvider>(context, listen: false).logout();
                   // Clear stack and go to Home (which redirects to Login if not auth)
                   // Or directly to LoginScreen if we want to be explicit
                   Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, {bool isLogout = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLogout ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.redAccent : Colors.white, 
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: isLogout ? Colors.redAccent : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
