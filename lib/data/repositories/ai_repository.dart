import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/ai.dart';

class AiRepository {
  final ApiClient _client;

  AiRepository(this._client);

  /// Initializes a new consultant session with the AI RAG system
  Future<AiChatSession> startSession({String? context}) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.aiChatSessions,
        data: {if (context != null) 'context': context},
      );
      final data = ApiClient.unwrap(response);
      return AiChatSession.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Sends customer query and receives AI consultant answer
  Future<AiChatMessage> sendMessage({
    required String sessionToken,
    required String message,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.aiChatMessages,
        data: {
          'sessionToken': sessionToken,
          'message': message,
        },
      );
      final data = ApiClient.unwrap(response);
      return AiChatMessage.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Gets full conversation transcript for active session
  Future<List<AiChatMessage>> getChatHistory(String sessionToken) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.aiChatHistory(sessionToken),
      );
      final data = ApiClient.unwrap(response);
      final rawList = data is Map ? (data['items'] as List? ?? []) : (data as List? ?? []);

      return rawList
          .map((m) => AiChatMessage.fromJson(
              m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map)))
          .toList();
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }

  /// Ends the AI conversation session
  Future<void> endSession(String sessionToken) async {
    try {
      await _client.dio.delete(ApiEndpoints.aiChatEnd(sessionToken));
    } catch (e) {
      throw ApiClient.handleError(e);
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AiRepository(client);
});
