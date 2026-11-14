import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../data/models/rfq.dart';

class RfqDetailBiddingScreen extends StatelessWidget {
  final Rfq rfq;

  const RfqDetailBiddingScreen({super.key, required this.rfq});

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Đấu Thầu ${rfq.rfqNumber}',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // RFQ Overview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rfq.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('Số lượng: ${rfq.targetQuantity} hộp · Dự toán: ${_formatCurrency(rfq.targetBudget ?? 0)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Ghi chú: ${rfq.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bids Header
            const Row(
              children: [
                Icon(Icons.gavel_outlined, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Danh Sách Báo Giá Từ Các Xưởng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bid Cards
            ...rfq.bids.map((bid) {
              final unitPrice = (bid.quotedPrice / rfq.targetQuantity).roundToDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                  border: Border.all(color: AppColors.border, width: 0.8),
                  boxShadow: AppTokens.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bid.supplierName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Xưởng kiểm định', style: TextStyle(color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatCurrency(bid.quotedPrice),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(width: 6),
                        Text('(${_formatCurrency(unitPrice)}/hộp)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Ngày cam kết giao: ${bid.deliveryDate}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Ưu đãi: ${bid.note}', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 14),

                    // Accept Bid CTA
                    CustomButton(
                      title: 'Chấp thuận báo giá & Tiến hành ký HĐ',
                      size: ButtonSize.medium,
                      width: double.infinity,
                      onPress: () {
                        context.push(
                          '/contract-sign',
                          extra: {
                            'contractNumber': 'HD-${rfq.rfqNumber}-KD',
                            'bid': bid,
                            'rfq': rfq,
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
