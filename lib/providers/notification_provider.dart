import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/realtime/signalr_service.dart';
import '../data/models/notification_item.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final SignalRService _signalRService;

  NotificationNotifier(this._signalRService) : super(const NotificationState()) {
    _initMockNotifications();
    _initSignalR();
  }

  void _initMockNotifications() {
    state = state.copyWith(
      notifications: [
        NotificationItem(
          id: 'notif-1',
          title: 'Báo giá mới cho RFQ-2026-08',
          message: 'Xưởng Bánh Kinh Đô vừa gửi báo giá chi tiết: 380.000₫/hộp kèm quà tặng.',
          type: 'RFQ',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        NotificationItem(
          id: 'notif-2',
          title: 'Hợp đồng sẵn sàng ký số',
          message: 'Hợp đồng HD-2026-88 đã hoàn tất kiểm duyệt. Vui lòng ký số để giữ lịch giao hàng.',
          type: 'Contract',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationItem(
          id: 'notif-3',
          title: 'Ưu đãi đặt sớm mùa trăng',
          message: 'Giảm thêm 5% cho tất cả đơn hàng hoàn tất đặt cọc trước ngày 15/07.',
          type: 'Promo',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  void _initSignalR() {
    _signalRService.addListener((payload) {
      final notif = NotificationItem(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: payload['title']?.toString() ?? 'Thông báo mới',
        message: payload['message']?.toString() ?? '',
        type: payload['type']?.toString() ?? 'System',
        isRead: false,
        createdAt: DateTime.now(),
        data: payload['data'] as Map<String, dynamic>?,
      );

      state = state.copyWith(
        notifications: [notif, ...state.notifications],
      );
    });

    _signalRService.startConnection();
  }

  void markAsRead(String id) {
    state = state.copyWith(
      notifications: state.notifications.map((n) {
        if (n.id == id) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList(),
    );
  }

  void markAllAsRead() {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}

final signalRServiceProvider = Provider<SignalRService>((ref) => SignalRService());

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final signalR = ref.watch(signalRServiceProvider);
  return NotificationNotifier(signalR);
});
