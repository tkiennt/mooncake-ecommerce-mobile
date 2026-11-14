import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../data/models/rfq.dart';

class RfqListScreen extends StatelessWidget {
  const RfqListScreen({super.key});

  static final List<Rfq> mockRfqs = [
    Rfq(
      id: 'rfq-1',
      rfqNumber: 'RFQ-2026-08',
      title: 'Đơn hàng 500 hộp quà đối tác VIP',
      targetQuantity: 500,
      targetBudget: 220000000,
      status: 'OpenForBidding',
      expectedDeliveryDate: DateTime.now().add(const Duration(days: 25)),
      notes: 'Hộp gỗ sơn mài dát vàng, in logo công ty, giao xe lạnh.',
      bids: [
        RfqBid(
          id: 'bid-1',
          supplierName: 'Xưởng Bánh Kinh Đô Nghệ Nhân',
          quotedPrice: 195000000,
          deliveryDate: '28/08/2026',
          note: 'Miễn phí in logo kim loại và tặng kèm 500 túi xách lụa cao cấp.',
        ),
        RfqBid(
          id: 'bid-2',
          supplierName: 'Bánh Mứt Cổ Truyền Hà Nội',
          quotedPrice: 205000000,
          deliveryDate: '26/08/2026',
          note: 'Đã bao gồm chi phí xe lạnh bảo quản 22°C tận nơi.',
        ),
      ],
    ),
  ];

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Yêu Cầu Báo Giá B2B',
        showBack: true,
        rightIcon: Icons.add,
        rightLabel: 'Tạo RFQ',
        onRightPress: () => context.push('/create-rfq'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockRfqs.length,
        itemBuilder: (context, index) {
          final rfq = mockRfqs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: InkWell(
              onTap: () => context.push('/rfq-detail-bidding', extra: rfq),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rfq.rfqNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accent),
                        ),
                        child: Text(
                          '${rfq.bids.length} xưởng nộp bid',
                          style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(rfq.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text('Số lượng: ${rfq.targetQuantity} hộp · Dự toán: ${_formatCurrency(rfq.targetBudget ?? 0)}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hạn giao: ${DateFormat('dd/MM/yyyy').format(rfq.expectedDeliveryDate)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const Row(
                        children: [
                          Text('Xem so sánh báo giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ],
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
