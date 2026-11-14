class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'System',
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'System',
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}
