class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;
  final bool isFromMe;
  final List<String> attachments;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
    this.isFromMe = false,
    this.attachments = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sId = json['senderId']?.toString() ?? json['userId']?.toString() ?? '';
    final rawAtts = json['attachments'] as List? ?? [];

    return ChatMessage(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      threadId: json['threadId']?.toString() ?? '',
      senderId: sId,
      senderName: json['senderName']?.toString() ?? json['sender']?['fullName']?.toString(),
      content: json['content']?.toString() ?? json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : (json['sentAt'] != null
              ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isFromMe: json['isFromMe'] == true || (currentUserId != null && sId == currentUserId),
      attachments: rawAtts.map((a) => a is Map ? (a['url']?.toString() ?? '') : a.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'threadId': threadId,
    'senderId': senderId,
    if (senderName != null) 'senderName': senderName,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'isFromMe': isFromMe,
    'attachments': attachments,
  };
}

class ChatThread {
  final String id;
  final String shopId;
  final String shopName;
  final String? shopAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.shopId,
    required this.shopName,
    this.shopAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    final partner = json['partner'] as Map?;
    return ChatThread(
      id: json['id']?.toString() ?? json['threadId']?.toString() ?? '',
      shopId: json['shopId']?.toString() ?? partner?['shopId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ??
          partner?['displayName']?.toString() ??
          'Xưởng sản xuất B2B',
      shopAvatar: json['shopAvatar']?.toString() ?? partner?['avatarUrl']?.toString(),
      lastMessage: json['lastMessage']?.toString() ??
          json['lastMessagePreview']?.toString(),
      lastMessageAt: json['lastActivityAt'] != null
          ? DateTime.tryParse(json['lastActivityAt'].toString())
          : (json['lastMessageAt'] != null
              ? DateTime.tryParse(json['lastMessageAt'].toString())
              : null),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'shopName': shopName,
    if (shopAvatar != null) 'shopAvatar': shopAvatar,
    if (lastMessage != null) 'lastMessage': lastMessage,
    if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
    'unreadCount': unreadCount,
  };
}
