import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_profile_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<AdminProvider>(context, listen: false).fetchSettings(token);
      }
    });
  }

  void _updateSetting(String key, bool value) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
       Provider.of<AdminProvider>(context, listen: false).updateSetting({key: value}, token);
    }
  }

  Future<void> _showDangerConfirmation(String title, String content, Function onConfirm) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.white))
          ),
           ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               onConfirm();
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );
  }

  void _resetData(String type) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    final admin = Provider.of<AdminProvider>(context, listen: false);
    
    if (type == 'users') {
      _showDangerConfirmation(
        'Reset All User Data?', 
        'This will delete ALL users (except admins) and their reels. This action cannot be undone.',
        () async {
           bool success = await admin.resetAllUsers(token);
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Users Reset' : 'Failed')));
        }
      );
    } else if (type == 'reels') {
       _showDangerConfirmation(
        'Clear All Reels?', 
        'This will permanently delete ALL reels from the platform.',
        () async {
           bool success = await admin.clearAllReels(token);
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Reels Cleared' : 'Failed')));
        }
      );
    }
  }

  void _showUpdateProfileDialog(Map<String, dynamic>? user) {
    if (user == null) return;
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: const Text('Update Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               final auth = Provider.of<AuthProvider>(context, listen: false);
               bool success = await auth.updateProfile(nameController.text, emailController.text, null); // Image update omitted for simplicty in this dialog
               if (mounted) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Profile Updated' : 'Update Failed')));
               }
            },
            child: const Text('Save')
          ),
        ],
      )
    );
  }

  void _showChangePasswordDialog(bool isDark) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool obscureOld = true;
        bool obscureNew = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E2230) : Colors.white,
              title: Text('Change Password', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: oldPassController,
                    obscureText: obscureOld,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      labelStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => obscureOld = !obscureOld),
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                   TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'New Password', 
                      labelStyle: const TextStyle(color: Colors.grey), 
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      )
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                     final auth = Provider.of<AuthProvider>(context, listen: false);
                     bool success = await auth.updatePassword(newPassController.text, oldPassController.text);
                     if (mounted) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Password Changed' : 'Failed: ${auth.errorMessage}')));
                     }
                  },
                  child: const Text('Update')
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final globalSettings = admin.settings ?? {};
    final user = auth.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Dynamic BG
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Admin Account Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A3E) : Colors.white, // Card BG
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                     children: [
                       Icon(Icons.person_outline, color: theme.primaryColor), // Cyan
                       const SizedBox(width: 8),
                       Text('Admin Account', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16)),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildInputLabel('Admin Name', isDark),
                   const SizedBox(height: 8),
                   _buildReadOnlyInput(user?['name'] ?? 'Admin', isDark),
                   const SizedBox(height: 16),
                   _buildInputLabel('Admin Email', isDark),
                   const SizedBox(height: 8),
                   _buildReadOnlyInput(user?['email'] ?? 'admin@reel.com', isDark),
                   const SizedBox(height: 20),
                   Container(
                     height: 50,
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFF00D9FF), Color(0xFF7C3AED)], // Cyan to Purple Gradient
                         begin: Alignment.centerLeft,
                         end: Alignment.centerRight,
                       ),
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: [
                         BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                       ],
                     ),
                     child: ElevatedButton(
                       onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                          );
                       }, 
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.transparent, 
                         shadowColor: Colors.transparent,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                       ),
                       child: const Text('Update Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                     ),
                   )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. App Controls
            _buildSectionHeader('App Controls', Icons.settings_outlined, theme),
            Container(
               decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    'Enable Reel Uploads', 
                    'Allow users to upload new reels',
                    globalSettings['enableReelUploads'] ?? true,
                    (val) => _updateSetting('enableReelUploads', val),
                    icon: Icons.upload_file_outlined,
                    iconColor: const Color(0xFF00D9FF), // Cyan
                    isDark: isDark
                  ),
                   Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 1),
                   _buildSwitchTile(
                    'Enable Automation', 
                    'Automated content moderation', 
                    globalSettings['enableAutomation'] ?? false,
                    (val) => _updateSetting('enableAutomation', val),
                    icon: Icons.bolt_outlined,
                    iconColor: const Color(0xFF7C3AED), // Purple
                    isDark: isDark
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),

            // 3. Security
             _buildSectionHeader('Security', Icons.shield_outlined, theme),
            Container(
               decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                children: [
                   _buildSwitchTile(
                    'Two-Factor Authentication', 
                    'Extra security for your account', 
                    globalSettings['enable2FA'] ?? false,
                    (val) => _updateSetting('enable2FA', val),
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF10B981), // Green
                    isDark: isDark
                  ),
                  Divider(color: isDark ? Colors.white10 : Colors.grey[200], height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.password, color: theme.iconTheme.color, size: 20),
                    ),
                    title: Center(child: Text('Change Password', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold))),
                    onTap: () {
                       _showChangePasswordDialog(isDark);
                    },
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ).run( (w) => Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0A0A1F) : Colors.grey[100], // Darker inset
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent)
                      ),
                      child: w
                  )),
                ],
              ),
            ),

            const SizedBox(height: 24),

             // 4. Notifications
             _buildSectionHeader('Notifications', Icons.notifications_outlined, theme),
             Container(
               decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.0 : 0.05), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                children: [
                   _buildSwitchTile(
                    'Email Notifications', 
                    'Receive admin alerts via email', 
                    globalSettings['emailNotifications'] ?? true,
                    (val) => _updateSetting('emailNotifications', val),
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF3B82F6), // Blue
                    isDark: isDark
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),

            // 5. Danger Zone
             const Align(alignment: Alignment.centerLeft, child: Text('Danger Zone', style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.bold))),
             const SizedBox(height: 12),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1E1010), 
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3))
               ),
               child: Column(
                 children: [
                   _buildDangerButton('Reset All User Data', () => _resetData('users')),
                   const SizedBox(height: 12),
                   _buildDangerButton('Clear All Reels', () => _resetData('reels')),
                 ],
               ),
             ),
             const SizedBox(height: 40),
             
              ListTile(
               leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
               title: const Text('Logout', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
               onTap: () => auth.logout(),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D9FF), size: 18), // Cyan icons
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Text(label, style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500));
  }

  Widget _buildReadOnlyInput(String value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A1F) : Colors.grey[100], // Very dark input background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, {required IconData icon, required Color iconColor, required bool isDark}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Taller tiles
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: TextStyle(color: isDark ? const Color(0xFF8F9BB3) : Colors.grey[600], fontSize: 13)),
      ),
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: value, 
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF00C6FF), // Bright Cyan
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildDangerButton(String title, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 54, // Taller buttons
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4B4B).withOpacity(0.5))
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
           foregroundColor: const Color(0xFFFF4B4B),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
        ),
        child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

extension RunExt on Widget {
  Widget run(Widget Function(Widget) block) {
    return block(this);
  }
}
