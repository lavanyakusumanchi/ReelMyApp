import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart'; // NEW
import '../../utils/app_localizations.dart'; // NEW
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State for toggles - now managed by Provider for global settings
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context); // Consume Settings
    final user = auth.user;
    final bool hasSetPassword = user?['hasSetPassword'] ?? false;
    
    // Helper for translation
    String t(String key) => AppLocalizations.of(context).translate(key);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dynamic Background
      appBar: AppBar(
        title: Text(t('settings'), style: Theme.of(context).appBarTheme.titleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(t('account')),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: t('change_password'),
            onTap: () {
               _showUpdatePasswordDialog(context, hasSetPassword);
            },
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: t('privacy'),
            onTap: () => _showPrivacyInfo(context),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader(t('notifications')),
          _buildSwitchTile(
            icon: Icons.notifications_none, 
            title: t('push_notifications'), 
            value: settings.notificationsEnabled, // Connected to Provider
            onChanged: (val) => settings.toggleNotifications(val)
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(t('appearance')),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined, 
            title: t('dark_mode'), 
            value: settings.themeMode == ThemeMode.dark, 
            onChanged: (val) => settings.toggleTheme(val)
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: t('language'),
            subtitle: settings.locale.languageCode == 'te' ? t('telugu') : t('english'),
            onTap: () => _showLanguageDialog(context, settings),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(t('video_preferences')),
           _buildSwitchTile(
            icon: Icons.play_circle_outline, 
            title: t('auto_play'), // Using 'auto_play' key but logic will be for auto-scroll
            value: settings.autoScrollEnabled, // Mapped to Auto Scroll
            onChanged: (val) => settings.toggleAutoScroll(val)
          ),

           _buildSwitchTile(
            icon: Icons.wifi,
            title: t('data_usage'), // Labelled 'Data Usage' but functionality is Data Saver
            value: settings.dataSaver,
            onChanged: (val) => settings.toggleDataSaver(val)
          ),
          
           const SizedBox(height: 40),
           SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(t('logout')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () {
                    auth.logout();
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }, 
                ),
          )

        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider settings) {
      showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).cardColor,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      ListTile(
                          leading: const Text("🇺🇸", style: TextStyle(fontSize: 20)),
                          title: const Text("English", style: TextStyle(color: Colors.white)),
                          onTap: () {
                              settings.setLocale('en');
                              Navigator.pop(ctx);
                          },
                          trailing: settings.locale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.blue) : null,
                      ),
                      ListTile(
                          leading: const Text("🇮🇳", style: TextStyle(fontSize: 20)),
                          title: const Text("Telugu (తెలుగు)", style: TextStyle(color: Colors.white)),
                          onTap: () {
                              settings.setLocale('te');
                              Navigator.pop(ctx);
                          },
                          trailing: settings.locale.languageCode == 'te' ? const Icon(Icons.check, color: Colors.blue) : null,
                      )
                  ]
              ),
            ),
          )
      );
  }

  void _showPrivacyInfo(BuildContext context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          title: const Text("Privacy Policy", style: TextStyle(color: Colors.white)),
          content: const Text(
            "Your privacy is important to us.\n\n"
            "• We collect basic usage data to improve your experience.\n"
            "• We do not share your personal data with third parties.\n"
            "• You can request data deletion at any time.",
            style: TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            )
          ],
        )
      );
  }

  void _showDownloadQualityDialog(BuildContext context, SettingsProvider settings) {
     showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E2E),
        builder: (ctx) => Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             for (var quality in ['High', 'Medium', 'Low'])
               ListTile(
                 title: Text(quality, style: const TextStyle(color: Colors.white)),
                 trailing: settings.downloadQuality == quality ? const Icon(Icons.check, color: Colors.blueAccent) : null,
                 onTap: () {
                    settings.setDownloadQuality(quality);
                    Navigator.pop(ctx);
                 },
               )
           ],
        )
     );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    String? subtitle,
    required VoidCallback onTap, 
    Widget? trailing
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon, 
    required String title, 
    required bool value, 
    required Function(bool) onChanged
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blueAccent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Copied from ProfileScreen to ensure functionality works here 
  void _showUpdatePasswordDialog(BuildContext context, bool hasSetPassword) {
    final oldPasswordController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    
    // Visibility Toggles
    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;

    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), 
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(1), 
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.withOpacity(0.5), Colors.purpleAccent.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                      hasSetPassword ? "Update Password" : "Set Password", 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                        hasSetPassword ? "Secure your account" : "Create your first password",
                                        style: const TextStyle(color: Colors.white54, fontSize: 13)
                                    )
                                ]
                            ),
                            Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.lock_outline, color: Colors.blueAccent)
                            )
                          ],
                        ),
                        const SizedBox(height: 30),

                        if (hasSetPassword) ...[
                          _buildPremiumTextField(
                            controller: oldPasswordController,
                            label: "Current Password",
                            isVisible: showOld,
                            onToggle: () => setState(() => showOld = !showOld),
                          ),
                          const SizedBox(height: 10),
                        ],

                        _buildPremiumTextField(
                          controller: passwordController,
                          label: "New Password",
                          isVisible: showNew,
                          onToggle: () => setState(() => showNew = !showNew),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildPremiumTextField(
                          controller: confirmController,
                          label: "Confirm Password",
                          isVisible: showConfirm,
                          onToggle: () => setState(() => showConfirm = !showConfirm),
                        ),
                        
                        // Error Message
                        if (error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                             padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                                children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)))
                                ]
                            )
                          ),

                        const SizedBox(height: 30),
                        
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                                ),
                                child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 10,
                                  shadowColor: Colors.blueAccent.withOpacity(0.4),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                                ),
                                onPressed: isLoading ? null : () async {
                                  if (passwordController.text != confirmController.text) {
                                    setState(() => error = "Passwords do not match");
                                    return;
                                  }
                                  if (passwordController.text.length < 8) {
                                    setState(() => error = "Password must be at least 8 chars");
                                    return;
                                  }
                                  if (hasSetPassword && oldPasswordController.text.isEmpty) {
                                     setState(() => error = "Please enter current password");
                                     return;
                                  }

                                  setState(() { isLoading = true; error = null; });
                                  
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  final success = await auth.updatePassword(
                                    passwordController.text,
                                    hasSetPassword ? oldPasswordController.text : null
                                  );
                                  
                                  setState(() => isLoading = false);

                                  if (success) {
                                    if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated!")));
                                    }
                                  } else {
                                     setState(() => error = auth.errorMessage ?? "Failed to update");
                                  }
                                },
                                child: isLoading 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                    : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        )

                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildPremiumTextField({
      required TextEditingController controller, 
      required String label, 
      required bool isVisible, 
      required VoidCallback onToggle
  }) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: TextField(
              controller: controller,
              obscureText: !isVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.grey),
                  floatingLabelStyle: const TextStyle(color: Colors.blueAccent),
                  suffixIcon: IconButton(
                      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white38),
                      onPressed: onToggle,
                  )
              ),
          )
      );
  }
}
