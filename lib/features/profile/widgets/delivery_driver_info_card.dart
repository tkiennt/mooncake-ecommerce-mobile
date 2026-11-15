import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class DeliveryDriverInfoCard extends StatelessWidget {
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final DateTime? driverClaimedAt;
  final String? trackingCode;
  final String? deliveryNumber;

  const DeliveryDriverInfoCard({
    super.key,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.driverClaimedAt,
    this.trackingCode,
    this.deliveryNumber,
  });

  bool get hasDriver =>
      driverClaimedAt != null ||
      (driverName != null && driverName!.trim().isNotEmpty);

  void _handleCallDriver(BuildContext context) {
    final phone = driverPhone ?? '';
    final name = driverName ?? 'Tài xế';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryTint,
                  radius: 22,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: AppTokens.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (vehiclePlate != null && vehiclePlate!.isNotEmpty)
                        Text(
                          'Biển số xe: $vehiclePlate',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: AppTokens.spaceSM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        phone.isNotEmpty ? phone : 'Chưa có số điện thoại',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (phone.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Sao chép', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép số điện thoại $phone vào bộ nhớ tạm.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đang kết nối cuộc gọi tới tài xế $name ($phone)...'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              icon: const Icon(Icons.phone_forwarded),
              label: const Text(
                'Gọi tài xế ngay',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),
          ],
        ),
      ),
    );
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Thông Tin Vận Chuyển & Tài Xế',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (deliveryNumber != null && deliveryNumber!.isNotEmpty)
                Text(
                  deliveryNumber!,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMD),
          if (hasDriver) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FFED), // AntD success-bg
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: const Color(0xFFB7EB8F)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF52C41A), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Tài xế đã nhận chuyến: ${driverName ?? "Đang cập nhật"}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF389E0D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (vehiclePlate != null && vehiclePlate!.isNotEmpty) ...[
                    Text(
                      '• Biển số xe: $vehiclePlate',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (driverPhone != null && driverPhone!.isNotEmpty) ...[
                    Text(
                      '• Số điện thoại: $driverPhone',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (driverClaimedAt != null)
                    Text(
                      '• Thời điểm nhận: ${DateFormat('HH:mm dd/MM/yyyy').format(driverClaimedAt!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, AppTokens.minTapTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                    onPressed: () => _handleCallDriver(context),
                    icon: const Icon(Icons.phone_in_talk, size: 18),
                    label: const Text(
                      'Gọi tài xế',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_empty, color: AppColors.textMuted, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa có tài xế nhận',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
