import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  /// Gets customer notifications inbox with pagination and read filter
  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int pageSize = 20,
    String? category,
    bool? isRead,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (category != null && category.isNotEmpty) 'category': category,
        if (isRead != null) 'isRead': isRead,
      };

      final response = await _client.dio.get(
        ApiEndpoints.notifications,
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((n) => NotificationItem.fromJson(
              n is Map<String, dynamic> ? n : Map<String, dynamic>.from(n as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets count of unread notifications
  Future<int> getUnreadCount({String? category}) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.notificationUnreadCount,
        queryParameters: {
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      final data = ApiClient.unwrap(response);
      if (data is Map) {
        return (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
      return (data as num?)?.toInt() ?? 0;
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Marks a single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _client.dio.patch(ApiEndpoints.markNotificationRead(id));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Marks all notifications in category as read
  Future<void> markAllAsRead({String category = 'all'}) async {
    try {
      await _client.dio.post(
        ApiEndpoints.markAllNotificationsRead,
        data: {
          'category': category,
          'readThroughTimestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets customer notification preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.notificationPreferences);
      final data = ApiClient.unwrap(response);
      return data is Map<String, dynamic> ? data : {};
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Updates notification channel preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _client.dio.put(
        ApiEndpoints.notificationPreferences,
        data: preferences,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client);
});
