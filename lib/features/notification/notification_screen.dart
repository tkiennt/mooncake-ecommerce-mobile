import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppHeader(
        title: 'Thông Báo',
        showBack: true,
        rightIcon: Icons.done_all,
        rightLabel: 'Đọc tất cả',
        onRightPress: () {
          ref.read(notificationProvider.notifier).markAllAsRead();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc.')),
          );
        },
      ),
      body: notifState.notifications.isEmpty
          ? const Center(
              child: Text('Không có thông báo nào.', style: TextStyle(color: AppColors.textMuted)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifState.notifications.length,
              itemBuilder: (context, index) {
                final notif = notifState.notifications[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: notif.isRead ? AppColors.surface : AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(color: notif.isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.3)),
                  ),
                  child: InkWell(
                    onTap: () => ref.read(notificationProvider.notifier).markAsRead(notif.id),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: notif.isRead ? AppColors.surfaceHover : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notif.type == 'RFQ'
                                ? Icons.gavel_outlined
                                : (notif.type == 'Contract' ? Icons.assignment_outlined : Icons.campaign_outlined),
                            size: 16,
                            color: notif.isRead ? AppColors.textSecondary : AppColors.textWhite,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('HH:mm · dd/MM/yyyy').format(notif.createdAt),
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
