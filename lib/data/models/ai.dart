class AiChatSession {
  final String sessionToken;
  final DateTime createdAt;

  AiChatSession({
    required this.sessionToken,
    required this.createdAt,
  });

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    return AiChatSession(
      sessionToken: json['sessionToken']?.toString() ??
          json['token']?.toString() ??
          '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionToken': sessionToken,
    'createdAt': createdAt.toIso8601String(),
  };
}

class AiChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id']?.toString() ?? json['messageId']?.toString() ?? '',
      role: json['role']?.toString() ??
          (json['isUser'] == true ? 'user' : 'assistant'),
      content: json['content']?.toString() ??
          json['message']?.toString() ??
          json['reply']?.toString() ??
          '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}
