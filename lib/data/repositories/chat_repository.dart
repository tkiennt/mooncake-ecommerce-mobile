import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/chat.dart';

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  /// Gets all active 1-1 conversation threads with workshops
  Future<List<ChatThread>> getThreads() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.chatThreads);
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((t) => ChatThread.fromJson(
              t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Opens or retrieves an existing conversation thread with a shop
  Future<ChatThread> openThread({
    required String shopId,
    String? supplierId,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.chatThreads,
        data: {
          'shopId': shopId,
          if (supplierId != null) 'supplierId': supplierId,
        },
      );
      final data = ApiClient.unwrap(response);
      return ChatThread.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets single thread info
  Future<ChatThread> getThread(String threadId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.chatThread(threadId));
      final data = ApiClient.unwrap(response);
      return ChatThread.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets message history for a thread
  Future<List<ChatMessage>> getMessages(
    String threadId, {
    int pageSize = 20,
    String? cursor,
    String? currentUserId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _client.dio.get(
        ApiEndpoints.chatMessages(threadId),
        queryParameters: queryParams,
      );

      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((m) => ChatMessage.fromJson(
                m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map),
                currentUserId: currentUserId,
              ))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Sends a text message or attachment to workshop
  Future<ChatMessage> sendMessage(
    String threadId, {
    required String content,
    List<String>? attachments,
    String? currentUserId,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.chatMessages(threadId),
        data: {
          'content': content,
          if (attachments != null && attachments.isNotEmpty)
            'attachments': attachments,
        },
      );
      final data = ApiClient.unwrap(response);
      return ChatMessage.fromJson(
        data as Map<String, dynamic>,
        currentUserId: currentUserId,
      );
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Marks all messages in thread as read
  Future<void> markThreadRead(String threadId) async {
    try {
      await _client.dio.post(ApiEndpoints.chatRead(threadId));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets unread message count across all chat threads
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.chatUnreadCount);
      final data = ApiClient.unwrap(response);
      if (data is Map) {
        return (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
      return (data as num?)?.toInt() ?? 0;
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatRepository(client);
});
