import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/antd/antd_steps.dart';
import '../../data/models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Chi Tiết ${order.orderCode}',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Timeline Card
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
                  const Text('Tiến Trình Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 14),
                  AntdSteps(
                    current: order.status == 'Delivered' ? 3 : 1,
                    items: const [
                      StepItemData(title: 'Đặt hàng', desc: 'Đã cọc 30%'),
                      StepItemData(title: 'Sản xuất', desc: 'Đang làm bánh'),
                      StepItemData(title: 'Giao hàng', desc: 'Xe lạnh 20-25°C'),
                      StepItemData(title: 'Nghiệm thu', desc: 'Ký biên bản PoD'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order Items
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danh Sách Sản Phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.imageUrl ?? 'assets/products/banh-nuong.jpg',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              if (item.variantName != null)
                                Text('Biến thể: ${item.variantName}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              Text('Số lượng: ${item.quantity} hộp', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Text(_formatCurrency(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping & Recipient Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông Tin Nhận Hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text('Người nhận: ${order.recipientName} (${order.recipientPhone})', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Địa chỉ: ${order.shippingAddress}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  if (order.deliveryNote != null) ...[
                    const SizedBox(height: 4),
                    Text('Ghi chú: ${order.deliveryNote}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row('Tổng tiền hàng:', _formatCurrency(order.totalAmount)),
                  const SizedBox(height: 6),
                  _row('Chiết khấu doanh nghiệp:', '-${_formatCurrency(order.discountAmount)}', color: AppColors.success),
                  const Divider(height: 20, color: AppColors.border),
                  _row('Tổng thanh toán:', _formatCurrency(order.finalAmount), isBold: true, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 14.5 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }
}
