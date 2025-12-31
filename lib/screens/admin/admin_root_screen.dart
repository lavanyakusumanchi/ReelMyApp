import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_reels_screen.dart';
import 'admin_settings_screen.dart';

class AdminRootScreen extends StatefulWidget {
  const AdminRootScreen({super.key});

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo_v6.png', width: 40, height: 40),
            const SizedBox(width: 12),
            const Text('ReelMyApp Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
        elevation: 0,
        actions: [
          // Theme Toggle
          Consumer<SettingsProvider>(
            builder: (ctx, settings, _) {
              final isDark = settings.themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.grey),
                onPressed: () => settings.toggleTheme(!isDark),
              );
            },
          ),
          // Logout
          TextButton.icon(
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
            label: const Text('Logout', style: TextStyle(color: Colors.grey)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
          ),
        ],
      ),
      body: _buildScreen(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF0A0A1F), // Main Background
        selectedItemColor: const Color(0xFF00D9FF), // Cyan Accent
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return AdminDashboardScreen(
          onViewAllReels: () => setState(() => _currentIndex = 2), // Switch to Reels
          onViewUsers: () => setState(() => _currentIndex = 1), // Switch to Users
        );
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminReelsScreen();
      case 3:
        return const AdminSettingsScreen();
      default:
        return const AdminDashboardScreen();
    }
  }
}
