import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/driver_trip.dart';
import '../../../shared_widgets/common/app_empty_state.dart';
import '../providers/driver_trip_provider.dart';
import '../storage/driver_storage.dart';

class DriverTripsListScreen extends ConsumerWidget {
  const DriverTripsListScreen({super.key});

  Future<void> _exitDriverMode(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát chế độ tài xế?'),
        content: const Text(
          'Bạn sẽ quay về màn hình đăng nhập. Danh sách chuyến đã mở vẫn được lưu trên thiết bị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ở lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await DriverStorage.setDriverModeActive(false);
      context.go('/login');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.success;
      case 'InTransit':
      case 'PickedUp':
        return AppColors.accent;
      case 'Disputed':
      case 'Failed':
        return AppColors.error;
      case 'AwaitingCustomerConfirmation':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Delivered':
        return AppColors.successBg;
      case 'InTransit':
      case 'PickedUp':
        return AppColors.accentGoldBg;
      case 'Disputed':
      case 'Failed':
        return AppColors.errorBg;
      case 'AwaitingCustomerConfirmation':
        return AppColors.infoBg;
      default:
        return AppColors.surfaceHover;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(savedTripsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Chuyến của tôi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined,
                color: AppColors.textSecondary),
            tooltip: 'Dọn dẹp chuyến hết hạn / đã hoàn tất',
            onPressed: () async {
              final cleaned = await ref
                  .read(savedTripsProvider.notifier)
                  .removeExpiredOrDelivered();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      cleaned > 0
                          ? 'Đã xoá $cleaned chuyến đã giao hoặc hết hạn.'
                          : 'Không có chuyến nào cần dọn dẹp.',
                    ),
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            onPressed: () => _exitDriverMode(context),
            icon: const Icon(Icons.logout, size: 18, color: AppColors.primary),
            label: const Text(
              'Thoát',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: tripsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text(
            'Lỗi tải danh sách chuyến: $err',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(savedTripsProvider.notifier).refreshAll(),
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  AppEmptyState(
                    title: 'Chưa có chuyến giao nào',
                    message:
                        'Nhập mã chuyến hoặc quét mã QR do xưởng cung ứng chia sẻ để bắt đầu nhận và giao hàng.',
                    actionLabel: 'Nhập mã chuyến mới',
                    onAction: () => context.push('/driver/entry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(savedTripsProvider.notifier).refreshAll(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceLG,
                vertical: AppTokens.spaceLG,
              ),
              itemCount: trips.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.spaceMD),
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _DriverTripCard(
                  trip: trip,
                  statusColor: _getStatusColor(trip.status),
                  statusBg: _getStatusBg(trip.status),
                  onTap: () {
                    ref.read(currentTripProvider.notifier).state = trip;
                    if (!trip.isClaimed) {
                      context.push('/driver/claim', extra: trip);
                    } else {
                      context.push('/driver/detail', extra: trip);
                    }
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xoá chuyến?'),
                        content: Text(
                          'Xoá chuyến ${trip.shareCode ?? trip.deliveryNumber} khỏi danh sách lưu trên máy?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Huỷ'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              'Xoá',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(savedTripsProvider.notifier).removeTrip(
                            token: trip.token,
                            shareCode: trip.shareCode,
                            deliveryId: trip.deliveryId,
                          );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceMD,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTokens.shadowCard,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/driver/entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              'Thêm chuyến giao mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  final DriverTrip trip;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DriverTripCard({
    required this.trip,
    required this.statusColor,
    required this.statusBg,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final expireText = trip.expiresAtUtc != null
        ? dateFormat.format(trip.expiresAtUtc!.toLocal())
        : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Code + Batch badge + Delete button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                    child: Text(
                      trip.shareCode ?? trip.deliveryNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceSM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                    child: Text(
                      trip.batchDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textMuted),
                    tooltip: 'Xoá chuyến',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMD),

              // Destination Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppTokens.spaceSM),
                  Expanded(
                    child: Text(
                      trip.toAddress ?? 'Chưa có địa chỉ giao hàng',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceSM),

              // Recipient Info
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: AppColors.textMuted),
                  const SizedBox(width: AppTokens.spaceSM),
                  Text(
                    trip.recipientName ?? 'Người nhận',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (trip.recipientPhone != null) ...[
                    const Text(' • ',
                        style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      trip.recipientPhone!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTokens.spaceMD),
              const Divider(height: 1),
              const SizedBox(height: AppTokens.spaceSM),

              // Status & Expiry Footer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                    child: Text(
                      trip.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (expireText != null) ...[
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Hạn: $expireText',
                      style: TextStyle(
                        fontSize: 11,
                        color: trip.isExpired
                            ? AppColors.error
                            : AppColors.textMuted,
                        fontWeight: trip.isExpired
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
