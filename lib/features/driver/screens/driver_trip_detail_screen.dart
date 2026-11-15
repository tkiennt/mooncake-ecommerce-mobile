import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/driver_trip.dart';
import '../../../data/repositories/driver_trip_repository.dart';
import '../providers/driver_trip_provider.dart';
import '../storage/driver_storage.dart';

class DriverTripDetailScreen extends ConsumerStatefulWidget {
  final DriverTrip? trip;

  const DriverTripDetailScreen({super.key, this.trip});

  @override
  ConsumerState<DriverTripDetailScreen> createState() =>
      _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState
    extends ConsumerState<DriverTripDetailScreen> {
  DriverTrip? _trip;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip ?? ref.read(currentTripProvider);
  }

  Future<void> _refreshTrip() async {
    final token = _trip?.token;
    final code = _trip?.shareCode;
    if (token == null && code == null) return;

    setState(() => _isRefreshing = true);
    try {
      final repo = ref.read(driverTripRepositoryProvider);
      DriverTrip updated;
      if (token != null && token.isNotEmpty) {
        updated = await repo.getTripByToken(token);
      } else {
        updated = await repo.getTripByCode(code!);
      }
      await ref.read(savedTripsProvider.notifier).saveTrip(updated);
      ref.read(currentTripProvider.notifier).state = updated;
      if (mounted) {
        setState(() => _trip = updated);
      }
    } catch (_) {
      // Ignored for refresh errors
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể gọi đến số $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở ứng dụng gọi điện.')),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    final encoded = Uri.encodeComponent(address);
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở bản đồ.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi mở bản đồ chỉ đường.')),
        );
      }
    }
  }

  Future<void> _exitDriverMode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát chế độ tài xế?'),
        content: const Text('Bạn sẽ quay lại màn hình đăng nhập khách hàng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Thoát', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await DriverStorage.setDriverModeActive(false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip ?? ref.watch(currentTripProvider);
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết chuyến')),
        body: const Center(child: Text('Không tìm thấy thông tin chuyến')),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final claimedTimeText = trip.driverClaimedAt != null
        ? dateFormat.format(trip.driverClaimedAt!.toLocal())
        : 'Chưa nhận';
    final scheduledText = trip.scheduledDate != null
        ? DateFormat('dd/MM/yyyy').format(trip.scheduledDate!.toLocal())
        : 'Chưa có lịch';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          trip.shareCode ?? trip.deliveryNumber,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Làm mới',
            onPressed: _isRefreshing ? null : _refreshTrip,
          ),
          TextButton.icon(
            onPressed: _exitDriverMode,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTrip,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLG,
              vertical: AppTokens.spaceLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top status card
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppTokens.shadowSubtle,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: trip.isDelivered
                              ? AppColors.successBg
                              : AppColors.primaryTint,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusDefault),
                        ),
                        child: Text(
                          trip.statusDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: trip.isDelivered
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceMD),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusDefault),
                        ),
                        child: Text(
                          trip.batchDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (trip.proofCount > 0) ...[
                        const Icon(Icons.photo_library_outlined,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          '${trip.proofCount} ảnh PoD',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Order Information Section
                _SectionCard(
                  title: 'Thông tin đơn hàng',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _InfoRow(
                      label: 'Mã đơn / Hợp đồng',
                      value: trip.orderDisplay,
                      isBold: true,
                    ),
                    if (trip.recipientCompanyName != null &&
                        trip.recipientCompanyName!.isNotEmpty)
                      _InfoRow(
                        label: 'Doanh nghiệp nhận',
                        value: trip.recipientCompanyName!,
                      ),
                    _InfoRow(
                      label: 'Lịch hẹn giao',
                      value: scheduledText,
                    ),
                    if (trip.notes != null && trip.notes!.isNotEmpty)
                      _InfoRow(
                        label: 'Ghi chú đóng gói / giao',
                        value: trip.notes!,
                        valueColor: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Driver & Claim Info
                _SectionCard(
                  title: 'Thông tin tài xế nhận chuyến',
                  icon: Icons.badge_outlined,
                  children: [
                    _InfoRow(
                      label: 'Tài xế đã nhận',
                      value: trip.driverName ?? 'Chưa nhận chuyến',
                      isBold: true,
                    ),
                    _InfoRow(
                      label: 'Biển số xe',
                      value: trip.vehiclePlate ?? '—',
                    ),
                    _InfoRow(
                      label: 'Thời điểm nhận',
                      value: claimedTimeText,
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Pickup & Delivery Locations
                _SectionCard(
                  title: 'Địa điểm giao nhận',
                  icon: Icons.map_outlined,
                  children: [
                    if (trip.fromAddress != null &&
                        trip.fromAddress!.isNotEmpty) ...[
                      const Text(
                        'Điểm lấy hàng (Kho xưởng):',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.fromAddress!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                    ],

                    const Text(
                      'Địa chỉ giao hàng:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.toAddress ?? 'Chưa có địa chỉ giao hàng',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSM),

                    // Map action button
                    if (trip.toAddress != null &&
                        trip.toAddress!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _openMap(trip.toAddress!),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.info),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTokens.radiusDefault),
                            ),
                          ),
                          icon: const Icon(Icons.navigation_outlined,
                              size: 16, color: AppColors.info),
                          label: const Text(
                            'Mở bản đồ dẫn đường',
                            style: TextStyle(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Recipient Info & Call Button
                _SectionCard(
                  title: 'Người nhận hàng',
                  icon: Icons.person_pin_circle_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.recipientName ?? 'Chưa rõ họ tên',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip.recipientPhone ?? 'Chưa có SĐT',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (trip.recipientPhone != null &&
                            trip.recipientPhone!.isNotEmpty) ...[
                          ElevatedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(trip.recipientPhone!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.spaceLG,
                                vertical: AppTokens.spaceMD,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.radiusDefault),
                              ),
                            ),
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text(
                              'Gọi điện',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceLG),

                // Items list (NO PRICES ALLOWED)
                _SectionCard(
                  title: 'Danh sách hàng cần giao (${trip.items.length} mục)',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    if (trip.items.isEmpty)
                      const Text(
                        'Chi tiết kiện hàng theo chứng từ niêm phong.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: trip.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (_, idx) {
                          final item = trip.items[idx];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHover,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceMD),
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
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
                                  color: AppColors.accentGoldBg,
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radiusDefault),
                                ),
                                child: Text(
                                  '${item.quantity} ${item.unit ?? "Hộp"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceMD,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTokens.shadowElevated,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: !trip.canSubmitProof
              ? Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  ),
                  child: const Text(
                    'Chuyến giao này đã hoàn tất hoặc ở chế độ chỉ xem.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    ref.read(currentTripProvider.notifier).state = trip;
                    context.push('/driver/proof', extra: trip);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 22),
                  label: const Text(
                    'Chụp nghiệm thu PoD',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppTokens.spaceSM),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          const Divider(height: 1),
          const SizedBox(height: AppTokens.spaceMD),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
