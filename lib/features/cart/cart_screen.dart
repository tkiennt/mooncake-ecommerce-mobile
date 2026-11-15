import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(cartProvider.notifier)
          .syncServerQuote(ref.read(apiClientProvider));
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final totals = cartState.totals;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Giỏ Hàng Doanh Nghiệp',
        showBack: false,
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Giỏ hàng của bạn đang trống',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khám phá ngay các bộ sưu tập bánh trung thu cao cấp',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      title: 'Khám phá sản phẩm',
                      onPress: () => context.go('/search'),
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
                  // List of Cart Items
                  ...cartState.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppTokens.lucianRadiusLg),
                        border:
                            Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: AppTokens.shadowSubtle,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.product.coverImage != null &&
                                    item.product.coverImage!.startsWith('http')
                                ? Image.network(
                                    item.product.coverImage!,
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/products/banh-nuong.jpg',
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    item.product.coverImage ??
                                        'assets/products/banh-nuong.jpg',
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 75,
                                      height: 75,
                                      color: AppColors.background,
                                      child: const Icon(Icons.cake,
                                          color: AppColors.primary),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.variant != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Vị: ${item.variant!.name}',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatCurrency(item.unitPrice),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Stepper & Delete
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.product.id,
                                              item.variant?.id,
                                              item.quantity - 1,
                                            );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20,
                                          color: AppColors.primary),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .updateQuantity(
                                              item.product.id,
                                              item.variant?.id,
                                              item.quantity + 1,
                                            );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20, color: AppColors.error),
                                      onPressed: () {
                                        ref
                                            .read(cartProvider.notifier)
                                            .removeFromCart(
                                              item.product.id,
                                              item.variant?.id,
                                            );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // Coupon Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusDefault),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Nhập mã giảm giá (ví dụ: B2BMOON2026)',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          title: 'Áp dụng',
                          size: ButtonSize.small,
                          onPress: () {
                            if (_couponController.text.isNotEmpty) {
                              ref
                                  .read(cartProvider.notifier)
                                  .applyCoupon(_couponController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Mã giảm giá đã được áp dụng!')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Breakdown Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.lucianRadiusLg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tạm tính (${totals.totalItems} hộp):',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                            if (cartState.isCalculatingQuote)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.8, color: AppColors.primary),
                              ),
                            Text(
                              _formatCurrency(totals.subtotal),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildRow('Chiết khấu bậc thang & mã:',
                            '-${_formatCurrency(totals.discountAmount)}',
                            isHighlight: true),
                        if (totals.taxAmount > 0) ...[
                          const SizedBox(height: 6),
                          _buildRow('Thuế VAT (8%):',
                              '+${_formatCurrency(totals.taxAmount)}'),
                        ],
                        if (totals.shippingFee > 0) ...[
                          const SizedBox(height: 6),
                          _buildRow('Phí vận chuyển xe lạnh:',
                              '+${_formatCurrency(totals.shippingFee)}'),
                        ],
                        const Divider(height: 20, color: AppColors.border),
                        _buildRow(
                            'Tổng thanh toán:',
                            _formatCurrency(totals.finalAmount),
                            isBold: true,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkout Button
                  CustomButton(
                    title: 'Tiến hành đặt cọc & thanh toán',
                    size: ButtonSize.large,
                    onPress: () => context.push('/checkout'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, bool isHighlight = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ??
                (isHighlight ? AppColors.success : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
