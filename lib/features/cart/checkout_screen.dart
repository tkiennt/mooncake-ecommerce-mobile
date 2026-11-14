import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController(text: 'Nguyễn Văn Kiên');
  final _phoneController = TextEditingController(text: '0901234567');
  final _addressController = TextEditingController(text: 'Tòa nhà FPT, Cầu Giấy, Hà Nội');
  final _noteController = TextEditingController(text: 'Giao hàng xe lạnh 20°C giờ hành chính');
  String _paymentMethod = 'vnpay'; // vnpay | cod | b2b_contract

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  void _handlePayment() {
    // Navigate to payment result
    context.go('/payment-result?success=true&orderCode=DH-2026-9921');
    ref.read(cartProvider.notifier).clearCart();
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(cartProvider).totals;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Thanh Toán Đơn Hàng',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shipping Address Card
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
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Địa chỉ giao nhận doanh nghiệp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên người nhận đại diện'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ kho / công ty'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Ghi chú vận chuyển (Xe lạnh, giờ giao)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Methods Card
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
                  const Text('Hình thức thanh toán / Ký quỹ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _buildPaymentRadio('vnpay', 'Cổng VNPay (Thẻ ATM / QR / Visa)', Icons.account_balance_wallet_outlined),
                  _buildPaymentRadio('b2b_contract', 'Đặt cọc 30% Hợp đồng & Ký quỹ', Icons.assignment_outlined),
                  _buildPaymentRadio('cod', 'Thanh toán khi nhận hàng & kiểm tra', Icons.local_shipping_outlined),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng số tiền cần trả:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    _formatCurrency(totals.finalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              title: 'Xác nhận đặt hàng & thanh toán',
              size: ButtonSize.large,
              onPress: _handlePayment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      activeColor: AppColors.primary,
      onChanged: (val) => setState(() => _paymentMethod = val!),
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      secondary: Icon(icon, color: AppColors.primary, size: 22),
      contentPadding: EdgeInsets.zero,
    );
  }
}
