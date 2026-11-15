import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/realtime/signalr_service.dart';
import '../data/models/notification_item.dart';
import 'auth_provider.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;
  final SignalRService _signalRService;
  final AuthState? _authState;
  SignalRNotificationCallback? _signalRCallback;

  NotificationNotifier(
    this._apiClient,
    this._signalRService, [
    this._authState,
  ]) : super(NotificationState(isLoading: _authState?.isAuthenticated ?? false)) {
    if (_authState?.isAuthenticated ?? false) {
      loadNotifications();
      _initSignalR();
    } else {
      _signalRService.stopConnection();
    }
  }

  /// Loads real notifications from backend
  Future<void> loadNotifications() async {
    final isAuthenticated = _authState?.isAuthenticated ?? false;
    if (!isAuthenticated) {
      state = state.copyWith(
        notifications: const [],
        isLoading: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.notifications);
      final rawData = response.data['data'] ?? response.data;
      final rawList = rawData is Map
          ? (rawData['items'] as List? ?? [])
          : (rawData as List? ?? []);

      final notifications = rawList
          .map((n) => NotificationItem.fromJson(
              n is Map<String, dynamic> ? n : Map<String, dynamic>.from(n as Map)))
          .toList();

      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      final err = ApiClient.handleError(e);
      state = state.copyWith(
        notifications: const [],
        isLoading: false,
        errorMessage: err.message.isNotEmpty
            ? err.message
            : 'Không thể tải danh sách thông báo.',
      );
    }
  }

  void _initSignalR() {
    final isAuthenticated = _authState?.isAuthenticated ?? false;
    if (!isAuthenticated) return;

    _signalRCallback = (payload) {
      final notif = NotificationItem(
        id: payload['id']?.toString() ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: payload['title']?.toString() ?? 'Thông báo mới',
        message: payload['message']?.toString() ?? payload['content']?.toString() ?? '',
        type: payload['type']?.toString() ?? payload['category']?.toString() ?? 'System',
        isRead: false,
        createdAt: DateTime.now(),
        data: payload['data'] as Map<String, dynamic>?,
      );

      state = state.copyWith(
        notifications: [notif, ...state.notifications],
      );
    };

    _signalRService.addListener(_signalRCallback!);
    _signalRService.startConnection();
  }

  /// Marks a notification as read both locally and in backend
  Future<void> markAsRead(String id) async {
    final isAuthenticated = _authState?.isAuthenticated ?? false;
    if (!isAuthenticated) return;

    // Optimistic local update
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );

    try {
      await _apiClient.dio.patch(ApiEndpoints.markNotificationRead(id));
    } catch (_) {
      // Best-effort sync
    }
  }

  /// Marks all notifications as read both locally and in backend
  Future<void> markAllAsRead() async {
    final isAuthenticated = _authState?.isAuthenticated ?? false;
    if (!isAuthenticated) return;

    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      await _apiClient.dio.post(
        ApiEndpoints.markAllNotificationsRead,
        data: {
          'category': 'all',
          'readThroughTimestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {
      // Best-effort sync
    }
  }

  Future<void> refresh() async {
    await loadNotifications();
  }

  @override
  void dispose() {
    if (_signalRCallback != null) {
      _signalRService.removeListener(_signalRCallback!);
    }
    super.dispose();
  }
}

final signalRServiceProvider = Provider<SignalRService>((ref) => SignalRService());

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final signalR = ref.watch(signalRServiceProvider);
  final authState = ref.watch(authProvider);
  return NotificationNotifier(apiClient, signalR, authState);
});
