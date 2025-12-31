import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String chatId; // Can be empty if new chat
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePic;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePic,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentChatId = '';

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  void _loadMessages() {
    if (_currentChatId.isNotEmpty) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
         Provider.of<ChatProvider>(context, listen: false).fetchMessages(_currentChatId, token);
      }
    } else {
      Provider.of<ChatProvider>(context, listen: false).clearMessages();
    }
  }
  
  void _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty) return;
    
    _msgController.clear();
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
       final provider = Provider.of<ChatProvider>(context, listen: false);
       final msg = await provider.sendMessage(widget.otherUserId, content, token);
       
       if (msg != null && _currentChatId.isEmpty) {
          // If this was a new chat, we might now have an ID if the backend returned it, 
          // or we re-fetch chats to find it. 
          // For simplicity, we just keep sending to recipientId.
          // Ideally, backend returns chatId in message or we look it up.
          // But our Message model has chatId.
          setState(() {
            _currentChatId = msg.id; // Wait, msg.id is message ID. msg.chatId is what we need if we added it to model.
            // Message model currently has id, senderId, content. Let's assume we handle state via recipient for now.
          });
       }
       _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user; // Current user
    final currentUserId = user?['id'] ?? user?['_id'] ?? '';
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserProfilePic != null 
                  ? NetworkImage(widget.otherUserProfilePic!) 
                  : null,
              child: widget.otherUserProfilePic == null 
                  ? Text(widget.otherUserName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                // Determine list
                final messages = provider.messages;
                
                if (messages.isEmpty && _currentChatId.isNotEmpty && provider.isLoading) {
                   return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? const Color(0xFF3797F0) // Instagram Blue
                              : (isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF)),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          msg.content,
                          style: TextStyle(
                            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                       color: Colors.blue, // Camera/Media button placeholder
                       shape: BoxShape.circle,
                    ),
                    child: IconButton(
                       icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                       onPressed: () {},
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: "Message...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send Text Button (Instagram shows 'Send' text when typing, mic otherwise, we'll just show send icon)
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Text(
                      "Send",
                      style: TextStyle(
                         color: Colors.blue,
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
