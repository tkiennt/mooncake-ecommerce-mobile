import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';

sealed class _NotificationListItem {}

class _DateHeaderItem extends _NotificationListItem {
  final String dateText;
  _DateHeaderItem(this.dateText);
}

class _NotificationEntryItem extends _NotificationListItem {
  final NotificationItem item;
  _NotificationEntryItem(this.item);
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  void _handleNotificationTap(BuildContext context, WidgetRef ref, NotificationItem notif) {
    if (!notif.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notif.id);
    }

    final type = notif.type.toLowerCase();
    final data = notif.data ?? {};

    if (type.contains('order') || data.containsKey('orderId')) {
      context.push('/orders');
    } else if (type.contains('rfq') || data.containsKey('rfqId')) {
      context.push('/rfq-list');
    } else if (type.contains('contract') || data.containsKey('contractId')) {
      context.push('/contracts');
    } else if (type.contains('delivery') || data.containsKey('deliveryId')) {
      context.push('/delivery-pod');
    } else if (type.contains('product') || data.containsKey('productId')) {
      context.push('/search');
    }
  }

  IconData _getNotificationIcon(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('order')) {
      return Icons.receipt_long_outlined;
    }
    if (lower.contains('rfq')) {
      return Icons.gavel_outlined;
    }
    if (lower.contains('contract')) {
      return Icons.assignment_outlined;
    }
    if (lower.contains('delivery')) {
      return Icons.local_shipping_outlined;
    }
    return Icons.campaign_outlined;
  }

  List<_NotificationListItem> _buildGroupedList(List<NotificationItem> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationItem>> groups = {};
    for (final notif in notifications) {
      final d = notif.createdAt;
      final itemDate = DateTime(d.year, d.month, d.day);
      String groupKey;
      if (itemDate == today) {
        groupKey = 'Hôm nay';
      } else if (itemDate == yesterday) {
        groupKey = 'Hôm qua';
      } else {
        groupKey = DateFormat('dd/MM/yyyy').format(d);
      }
      groups.putIfAbsent(groupKey, () => []).add(notif);
    }

    final List<_NotificationListItem> result = [];
    groups.forEach((key, items) {
      result.add(_DateHeaderItem(key));
      for (final item in items) {
        result.add(_NotificationEntryItem(item));
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Unauthenticated state: show empty state prompting to login
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeader(
          title: 'Thông báo',
          showBack: true,
        ),
        body: SafeArea(
          child: AppEmptyState(
            icon: Icons.lock_outline,
            title: 'Đăng nhập để xem thông báo',
            message: 'Bạn hãy đăng nhập để nhận cập nhật tiến độ đơn hàng, báo giá từ xưởng và hợp đồng nhé.',
            actionLabel: 'Đăng nhập ngay',
            onAction: () => context.push('/login'),
          ),
        ),
      );
    }

    final notifState = ref.watch(notificationProvider);
    final unreadCount = notifState.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Thông báo',
        showBack: true,
        rightIcon: unreadCount > 0 ? Icons.done_all : null,
        rightLabel: unreadCount > 0 ? 'Đọc tất cả' : null,
        onRightPress: unreadCount > 0
            ? () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đọc tất cả thông báo.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            : null,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
        child: _buildBody(context, ref, notifState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, NotificationState notifState) {
    if (notifState.isLoading && notifState.notifications.isEmpty) {
      return _buildSkeletonList();
    }

    if (notifState.errorMessage != null && notifState.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: AppErrorState(
              title: 'Chưa tải được thông báo',
              message: notifState.errorMessage,
              retryLabel: 'Thử lại',
              onRetry: () => ref.read(notificationProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    if (notifState.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Chưa có thông báo nào',
              message: 'Các cập nhật về đơn hàng, báo giá và hợp đồng sẽ xuất hiện tại đây.',
              actionLabel: 'Khám phá sản phẩm',
              onAction: () => context.go('/search'),
            ),
          ),
        ],
      );
    }

    final groupedItems = _buildGroupedList(notifState.notifications);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceSM,
      ),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final item = groupedItems[index];
        if (item is _DateHeaderItem) {
          return _buildDateHeader(item.dateText);
        } else if (item is _NotificationEntryItem) {
          return _buildNotificationCard(context, ref, item.item);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTokens.spaceLG,
        bottom: AppTokens.spaceSM,
        left: AppTokens.spaceXS,
        right: AppTokens.spaceXS,
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppTokens.radiusXS),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, NotificationItem notif) {
    final icon = _getNotificationIcon(notif.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
      decoration: BoxDecoration(
        color: notif.isRead ? AppColors.surface : AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: notif.isRead
              ? AppColors.border
              : AppColors.primaryLight.withValues(alpha: 0.35),
        ),
        boxShadow: AppTokens.elevationSubtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          onTap: () => _handleNotificationTap(context, ref, notif),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMD,
                vertical: AppTokens.spaceMD,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: notif.isRead ? AppColors.surfaceHover : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 18,
                        color: notif.isRead ? AppColors.textSecondary : AppColors.textWhite,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!notif.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: AppTokens.spaceSM),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spaceXS),
                        Text(
                          notif.message,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSM),
                        Text(
                          DateFormat('HH:mm · dd/MM/yyyy').format(notif.createdAt),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return AppSkeleton.shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton.circle(radius: 19),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSkeleton(width: 140, height: 14),
                      const SizedBox(height: AppTokens.spaceSM),
                      const AppSkeleton.text(height: 12),
                      const SizedBox(height: AppTokens.spaceXS),
                      const AppSkeleton.text(width: 180, height: 12),
                      const SizedBox(height: AppTokens.spaceSM),
                      const AppSkeleton(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
