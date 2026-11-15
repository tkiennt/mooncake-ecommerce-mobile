import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/order.dart';

class OrderDisputeRebuttalCard extends StatelessWidget {
  final OrderDeliveryDispute dispute;

  const OrderDisputeRebuttalCard({super.key, required this.dispute});

  String _formatDateTime(DateTime dt) =>
      DateFormat('HH:mm dd/MM/yyyy').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final isAwaiting = dispute.isAwaitingRebuttal;
    final hasRebuttal = dispute.supplierRebuttalNotes != null &&
        dispute.supplierRebuttalNotes!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: isAwaiting ? AppColors.warning : AppColors.error,
          width: 1.2,
        ),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isAwaiting ? Icons.pending_actions : Icons.report_problem,
                    color: isAwaiting ? AppColors.warning : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Khiếu Nại Đơn Hàng',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAwaiting ? const Color(0xFFFFF7E6) : const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(
                    color: isAwaiting ? const Color(0xFFFFD591) : const Color(0xFFFFA39E),
                  ),
                ),
                child: Text(
                  isAwaiting ? 'Chờ xưởng phản biện' : 'Đang giải quyết',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isAwaiting ? const Color(0xFFD46B08) : const Color(0xFFCF1322),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          if (dispute.reason.isNotEmpty) ...[
            Text(
              'Lý do khiếu nại: ${dispute.reason}',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (dispute.rebuttalDeadlineAt != null) ...[
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Hạn chót xưởng phản biện: ${_formatDateTime(dispute.rebuttalDeadlineAt!)}'
                    '${dispute.hoursUntilDeadline != null ? " (còn ${dispute.hoursUntilDeadline} giờ)" : ""}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceMD),
          ],

          // Rebuttal from supplier
          if (hasRebuttal) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F0FF), // AntD purple tint
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: const Color(0xFFD3ADF7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront, size: 16, color: Color(0xFF722ED1)),
                          SizedBox(width: 6),
                          Text(
                            'Nội dung phản biện từ xưởng:',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: Color(0xFF722ED1),
                            ),
                          ),
                        ],
                      ),
                      if (dispute.supplierRebuttalAt != null)
                        Text(
                          _formatDateTime(dispute.supplierRebuttalAt!),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dispute.supplierRebuttalNotes!,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (dispute.supplierRebuttalEvidenceUrls.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spaceSM),
                    const Text(
                      'Bằng chứng đính kèm từ xưởng:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dispute.supplierRebuttalEvidenceUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final url = dispute.supplierRebuttalEvidenceUrls[idx];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                            child: Image.network(
                              url,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.background,
                                child: const Icon(Icons.broken_image, size: 24, color: AppColors.textMuted),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (isAwaiting) ...[
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đang chờ xưởng sản xuất gửi văn bản phản biện và bằng chứng nghiệm thu trong vòng 48h.',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
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
