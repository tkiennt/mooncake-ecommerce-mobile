import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

class AutoConfirmBanner extends StatelessWidget {
  final DateTime deadline;
  final String? orderCode;
  final VoidCallback? onConfirmReceipt;

  const AutoConfirmBanner({
    super.key,
    required this.deadline,
    this.orderCode,
    this.onConfirmReceipt,
  });

  int get _hoursRemaining {
    final diff = deadline.difference(DateTime.now()).inHours;
    return diff < 0 ? 0 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('HH:mm dd/MM/yyyy').format(deadline.toLocal());
    final hours = _hoursRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.access_time_filled,
            color: AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo tự động xác nhận đã nhận hàng (SLA 72h)',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hệ thống sẽ tự xác nhận đã nhận hàng lúc $formattedDate (còn $hours giờ). '
                  'Nếu có vấn đề chất lượng hoặc số lượng, vui lòng bấm Khiếu nại trước thời điểm này.',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
