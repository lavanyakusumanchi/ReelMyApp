import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<ChatProvider>(context, listen: false).fetchChats(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:  theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Messages",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.chats.isEmpty) {
             // Show User Search if no chats
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUserId: chat.otherUserId,
                        otherUserName: chat.otherUserName,
                        otherUserProfilePic: chat.otherUserProfilePic,
                      ),
                    ),
                  ).then((_) {
                     // Refresh on return
                     final token = Provider.of<AuthProvider>(context, listen: false).token;
                     if (token != null) chatProvider.fetchChats(token);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                         radius: 28,
                         backgroundColor: Colors.transparent, // Cleaner
                         backgroundImage: chat.otherUserProfilePic != null 
                             ? NetworkImage(chat.otherUserProfilePic!)
                             : null,
                         child: chat.otherUserProfilePic == null 
                             ? Container(
                                 decoration: const BoxDecoration(
                                   shape: BoxShape.circle,
                                   gradient: LinearGradient(colors: [Colors.purple, Colors.orange]), 
                                 ),
                                 alignment: Alignment.center,
                                 child: Text(chat.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                               )
                             : null,
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.otherUserName,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.id.isEmpty ? "Start a conversation" : (chat.lastMessage ?? "No messages"), // Handle new/empty chats
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: chat.isRead ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                fontWeight: chat.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Time/Meta
                      if (chat.lastMessageTime != null)
                        Text(
                           timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                           style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Show search dialog/screen
           _showUserSearch(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
           const SizedBox(height: 20),
           Text("No messages yet", style: Theme.of(context).textTheme.titleMedium),
           const SizedBox(height: 10),
           TextButton(
             onPressed: () => _showUserSearch(context),
             child: const Text("Start a chat"),
           )
         ],
      ),
    );
  }

  void _showUserSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (_, scrollController) {
             return _UserSearchSheet(scrollController: scrollController);
          },
        );
      },
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _UserSearchSheet({required this.scrollController});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      final results = await Provider.of<ChatProvider>(context, listen: false).searchUsers(query, token);
      setState(() {
        _results = results;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
               Expanded(
                 child: TextField(
                   controller: _searchController,
                   decoration: InputDecoration(
                     hintText: "Search users...",
                     prefixIcon: const Icon(Icons.search),
                     filled: true,
                     fillColor: Colors.grey[200],
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                   ),
                   onSubmitted: (_) => _search(),
                 ),
               ),
               TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _searching 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                       final user = _results[index];
                       return ListTile(
                         leading: CircleAvatar(child: Text(user['name'][0].toUpperCase())),
                         title: Text(user['name']),
                         subtitle: Text(user['email']),
                         onTap: () {
                            Navigator.pop(context);
                            // Open Chat
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                    chatId: '', // New chat, ID unknown initially or Handle in ChatScreen via recipient
                                    otherUserId: user['_id'],
                                    otherUserName: user['name'],
                                    otherUserProfilePic: user['profile_pic'],
                                ),
                                ),
                            );
                         },
                       );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
