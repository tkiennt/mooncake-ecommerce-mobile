import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/cart_provider.dart';
import '../../data/repositories/order_repository.dart';

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
  String _paymentMethod = 'vnpay'; // vnpay | b2b_contract | cod
  bool _isSubmitting = false;

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

  Future<void> _handlePayment() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi thanh toán.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ tên người nhận, số điện thoại và địa chỉ giao hàng.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderRepo = ref.read(orderRepositoryProvider);

      // Resolve shopId from items or fallback
      final firstShopId = cartState.items
              .map((i) => i.product.shopId)
              .firstWhere((id) => id != null && id.isNotEmpty, orElse: () => null) ??
          '00000000-0000-0000-0000-000000000001';

      final itemsPayload = cartState.items.map((i) {
        final variantId = i.variant?.id ??
            (i.product.variants.isNotEmpty ? i.product.variants.first.id : i.product.id);
        return {
          'productId': i.product.id,
          'variantId': variantId,
          'quantity': i.quantity,
        };
      }).toList();

      final orderPayload = {
        'shopId': firstShopId,
        'items': itemsPayload,
        'deliveryAddress': address,
        'recipientName': name,
        'recipientPhone': phone,
        if (_noteController.text.trim().isNotEmpty)
          'notes': _noteController.text.trim(),
      };

      // 1. Create order via POST /api/v1/orders
      final order = await orderRepo.createOrder(orderPayload);

      // 2. If VNPay, call POST /api/v1/payments/orders/vnpay-url
      if (_paymentMethod == 'vnpay') {
        try {
          await orderRepo.createOrderVnPayUrl(
            orderId: order.id,
            returnUrl: 'https://mooncake.com/thanh-toan/ket-qua',
          );
        } catch (vnpayError) {
          debugPrint('VNPay URL generation notice: $vnpayError');
        }
      }

      // 3. Clear cart state
      ref.read(cartProvider.notifier).clearCart();

      // 4. Navigate to payment result screen
      if (mounted) {
        context.go('/payment-result?success=true&orderCode=${order.orderCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý đơn hàng: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(cartProvider).totals;
    final itemsCount = ref.watch(cartProvider).items.length;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Thanh Toán Đơn Hàng',
        showBack: true,
      ),
      body: itemsCount == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'Giỏ hàng của bạn đang trống',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vui lòng chọn sản phẩm trước khi tiến hành thanh toán.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      title: 'Quay lại giỏ hàng',
                      size: ButtonSize.large,
                      onPress: () => context.go('/cart'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                          keyboardType: TextInputType.phone,
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
                        const SizedBox(height: 14),
                        _buildPaymentOption(
                          value: 'vnpay',
                          title: 'Cổng VNPay (Thẻ ATM / QR / Visa)',
                          subtitle: 'Thanh toán trực tuyến bảo mật qua cổng VNPay',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _buildPaymentOption(
                          value: 'b2b_contract',
                          title: 'Đặt cọc 30% Hợp đồng & Ký quỹ',
                          subtitle: 'Ký quỹ theo tiến độ sản xuất và hợp đồng B2B',
                          icon: Icons.assignment_outlined,
                        ),
                        _buildPaymentOption(
                          value: 'cod',
                          title: 'Thanh toán khi nhận hàng & kiểm tra',
                          subtitle: 'Kiểm tra chất lượng và niêm phong trước khi thanh toán',
                          icon: Icons.local_shipping_outlined,
                        ),
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
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
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
                    title: _isSubmitting ? 'Đang tạo đơn hàng...' : 'Xác nhận đặt hàng & thanh toán',
                    size: ButtonSize.large,
                    loading: _isSubmitting,
                    onPress: _isSubmitting ? null : _handlePayment,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return InkWell(
      onTap: _isSubmitting ? null : () => setState(() => _paymentMethod = value),
      borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
