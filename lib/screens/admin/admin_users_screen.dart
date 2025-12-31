import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/api_config.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<AdminProvider>(context, listen: false).fetchUsers(token);
    }
  }

  void _manageUser(String userId, String action) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      bool success = await Provider.of<AdminProvider>(context, listen: false).manageUser(userId, action, token);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User $action success')));
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Filter logic
    final filteredUsers = admin.users.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final email = (user['email'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A3E) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF1F2937) : Colors.transparent),
          ),
          child: TextField(
            controller: _searchController,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12)
            ),
          ),
        ),
      ),
      body: admin.isLoading && admin.users.isEmpty
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : RefreshIndicator(
              color: theme.primaryColor,
              backgroundColor: theme.canvasColor,
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isBlocked = user['status'] == 'blocked';
                  final handle = '@${user['name'].toString().replaceAll(' ', '').toLowerCase()}';
                  final reelsCount = user['reelsCount'] ?? 0;


                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A3E) : Colors.white,
                      borderRadius: BorderRadius.circular(16), 
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: ListTile(
                      onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: user)),
                         );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: isDark ? const Color(0xFF2A2A4E) : Colors.grey[100],
                        backgroundImage: user['profile_pic'] != null && user['profile_pic'].isNotEmpty
                             ? NetworkImage(ApiConfig.getFullUrl(user['profile_pic']))
                             : null,
                        child: user['profile_pic'] == null || user['profile_pic'].isEmpty ? Text(user['name'][0], style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor)) : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(child: Text(user['name'], style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isBlocked ? const Color(0xFFEF4444).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBlocked ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.3), 
                                  width: 1
                                )
                              ),
                              child: Text(
                                user['status']?.toString().toLowerCase() ?? 'active',
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                           )
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(handle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                           const SizedBox(height: 2),
                           Text(user['email'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                           const SizedBox(height: 6),
                           Text(
                             '$reelsCount Reels',
                             style: TextStyle(color: Colors.grey[500], fontSize: 12),
                           ),
                         ],
                      ),
                      trailing: Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: isDark ? const Color(0xFF2A2E3D) : Colors.white,
                          dividerColor: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          color: isDark ? const Color(0xFF2A2E3D) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                             if (value == 'block') _manageUser(user['_id'], 'block');
                             if (value == 'unblock') _manageUser(user['_id'], 'unblock');
                             if (value == 'delete') _manageUser(user['_id'], 'delete');
                          },
                          itemBuilder: (context) => [
                            if (!isBlocked)
                              const PopupMenuItem(
                                value: 'block', 
                                child: Row(children: [
                                  Icon(Icons.person_off_outlined, color: Colors.orange, size: 20),
                                  SizedBox(width: 12),
                                  Text('Block User')
                                ])
                              ),
                            if (isBlocked)
                              const PopupMenuItem(
                                value: 'unblock', 
                                child: Row(children: [
                                  Icon(Icons.person_outline, color: Colors.green, size: 20),
                                  SizedBox(width: 12),
                                  Text('Unblock User')
                                ])
                              ),
                            const PopupMenuItem(
                              value: 'delete', 
                              child: Row(children: [
                                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Delete User', style: TextStyle(color: Colors.red))
                              ])
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
