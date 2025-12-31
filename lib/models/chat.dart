class Chat {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePic;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isRead;

  Chat({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePic,
    this.lastMessage,
    this.lastMessageTime,
    this.isRead = true,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    final otherUser = json['otherUser'] ?? {};
    final lastMsg = json['lastMessage'] ?? {};
    
    return Chat(
      id: json['id'] ?? '',
      otherUserId: otherUser['id'] ?? '',
      otherUserName: otherUser['name'] ?? 'Unknown',
      otherUserProfilePic: otherUser['profile_pic'],
      lastMessage: lastMsg['content'],
      lastMessageTime: lastMsg['timestamp'] != null 
          ? DateTime.parse(lastMsg['timestamp']) 
          : null,
      isRead: lastMsg['read'] ?? true, // Default to read if null
    );
  }
}
