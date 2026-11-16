// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/order_repository.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_price_tag.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/sticky_bottom_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameController = TextEditingController(text: 'Nguyễn Văn Kiên');
  final _phoneController = TextEditingController(text: '0901234567');
  final _addressController =
      TextEditingController(text: 'Tòa nhà FPT, Cầu Giấy, Hà Nội');
  final _noteController =
      TextEditingController(text: 'Giao trong giờ hành chính');

  String _paymentMethod = 'vnpay'; // vnpay | b2b_contract | cod
  bool _isSubmitting = false;
  bool _isVerifyingData = false;
  String? _checkoutError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCheckoutData();
    });
  }

  Future<void> _initCheckoutData() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    setState(() {
      _isVerifyingData = true;
      _checkoutError = null;
    });

    try {
      // Sync authoritative quote from server
      await ref
          .read(cartProvider.notifier)
          .syncServerQuote(ref.read(apiClientProvider));

      // Fetch shop bulk policy to verify minimum requirements
      final firstShopId = cartState.items
          .map((i) => i.product.shopId)
          .firstWhere((id) => id != null && id.isNotEmpty, orElse: () => null);

      if (firstShopId != null && firstShopId.isNotEmpty) {
        await ref.read(orderRepositoryProvider).getShopPolicy(firstShopId);
      }

      if (mounted) {
        setState(() {
          _isVerifyingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingData = false;
          _checkoutError = 'Chưa tải được thông tin thanh toán, bạn thử lại sau nhé.';
        });
      }
    }
  }

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
          content: Text(
              'Giỏ hàng đang trống. Bạn chọn thêm sản phẩm trước nhé.'),
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
          content: Text(
              'Bạn vui lòng nhập đầy đủ họ tên, số điện thoại và địa chỉ nhận hàng nhé.'),
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
              .firstWhere((id) => id != null && id.isNotEmpty,
                  orElse: () => null) ??
          '00000000-0000-0000-0000-000000000001';

      final itemsPayload = cartState.items.map((i) {
        final variantId = i.variant?.id ??
            (i.product.variants.isNotEmpty
                ? i.product.variants.first.id
                : i.product.id);
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
        'paymentMethod': _paymentMethod,
        if (_noteController.text.trim().isNotEmpty)
          'notes': _noteController.text.trim(),
      };

      // 1. Create order via real API POST /api/v1/orders
      final order = await orderRepo.createOrder(orderPayload);

      // 2. If VNPay, initiate payment URL
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
          const SnackBar(
            content: Text('Chưa tạo được đơn hàng, bạn thử lại sau nhé.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
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
    final cartState = ref.watch(cartProvider);
    final totals = cartState.totals;
    final itemsCount = cartState.items.length;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Thanh toán',
        showBack: true,
      ),
      body: _buildBody(cartState),
      bottomNavigationBar: itemsCount > 0
          ? StickyBottomBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _paymentMethod == 'b2b_contract'
                              ? 'Cần đặt cọc trước (30%)'
                              : 'Tổng thanh toán',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AppPriceTag(
                          price: _paymentMethod == 'b2b_contract'
                              ? totals.finalAmount * 0.3
                              : totals.finalAmount,
                          size: AppPriceTagSize.medium,
                          isBold: true,
                        ),
                        if (_paymentMethod == 'b2b_contract') ...[
                          const SizedBox(height: 1),
                          Text(
                            'Tổng đơn: ${_formatCurrency(totals.finalAmount)}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  CustomButton(
                    title: _isSubmitting
                        ? 'Đang tạo đơn...'
                        : (_paymentMethod == 'b2b_contract'
                            ? 'Xác nhận đặt cọc'
                            : 'Xác nhận đặt hàng'),
                    size: ButtonSize.large, // CTA >= 48px
                    loading: _isSubmitting,
                    onPress: _isSubmitting ? null : _handlePayment,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody(CartState cartState) {
    // 1. Loading State with AppSkeleton
    if (_isVerifyingData && cartState.items.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          children: [
            AppSkeleton.orderCard(),
            const SizedBox(height: AppTokens.spaceMD),
            AppSkeleton.orderCard(),
            const SizedBox(height: AppTokens.spaceMD),
            AppSkeleton.orderCard(),
          ],
        ),
      );
    }

    // 2. Error State with AppErrorState
    if (_checkoutError != null && cartState.items.isNotEmpty) {
      return AppErrorState(
        title: 'Chưa tải được thông tin thanh toán',
        message: _checkoutError,
        onRetry: _initCheckoutData,
        retryLabel: 'Thử lại',
      );
    }

    // 3. Empty State with AppEmptyState
    if (cartState.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Giỏ hàng đang trống',
        message:
            'Bạn hãy chọn sản phẩm vào giỏ hàng trước khi thanh toán nhé.',
        actionLabel: 'Quay lại giỏ hàng',
        onAction: () => context.go('/cart'),
      );
    }

    final totals = cartState.totals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shipping Address Card
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppTokens.elevationSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: AppTokens.spaceSM),
                    Text(
                      'Địa chỉ nhận hàng',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên người nhận *',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                      vertical: AppTokens.spaceMD,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại *',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                      vertical: AppTokens.spaceMD,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ nhận hàng *',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                      vertical: AppTokens.spaceMD,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú giao hàng (thời gian, chỉ dẫn nhận bánh,...)',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                      vertical: AppTokens.spaceMD,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spaceLG),

          // Payment Methods Card
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppTokens.elevationSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hình thức thanh toán',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                _buildPaymentOption(
                  value: 'vnpay',
                  title: 'Ví điện tử & Thẻ (VNPay)',
                  subtitle:
                      'Quét mã QR, thẻ ATM nội địa hoặc thẻ quốc tế (Visa/Mastercard)',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _buildPaymentOption(
                  value: 'b2b_contract',
                  title: 'Đặt cọc 30% theo hợp đồng',
                  subtitle:
                      'Thanh toán 30% trước, phần còn lại thanh toán khi nhận bánh',
                  icon: Icons.assignment_outlined,
                ),
                _buildPaymentOption(
                  value: 'cod',
                  title: 'Thanh toán khi nhận hàng (COD)',
                  subtitle:
                      'Kiểm tra bánh trước khi thanh toán cho nhân viên giao hàng',
                  icon: Icons.local_shipping_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spaceLG),

          // Order Summary Card (Tóm tắt đơn rõ ràng - D19: KHÔNG làm thẻ VAT riêng)
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppTokens.elevationSubtle,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 20, color: AppColors.primary),
                        SizedBox(width: AppTokens.spaceSM),
                        Text(
                          'Tóm tắt đơn hàng',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${totals.totalItems} hộp',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceMD),

                // Item Mini List
                ...cartState.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusSM),
                          child: item.product.coverImage != null &&
                                  item.product.coverImage!.startsWith('http')
                              ? Image.network(
                                  item.product.coverImage!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/products/banh-nuong.jpg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  item.product.coverImage ??
                                      'assets/products/banh-nuong.jpg',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.surfaceHover,
                                    child: const Icon(Icons.cake_outlined,
                                        size: 20, color: AppColors.primary),
                                  ),
                                ),
                        ),
                        const SizedBox(width: AppTokens.spaceSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.quantity} x ${_formatCurrency(item.unitPrice)}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(item.subtotal),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20, color: AppColors.border),

                _buildSummaryLine(
                  'Tạm tính:',
                  _formatCurrency(totals.subtotal),
                ),
                if (totals.discountAmount > 0) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryLine(
                    'Chiết khấu số lượng & mã:',
                    '-${_formatCurrency(totals.discountAmount)}',
                    color: AppColors.success,
                  ),
                ],
                if (totals.taxAmount > 0) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryLine(
                    'Thuế GTGT (8%):',
                    '+${_formatCurrency(totals.taxAmount)}',
                  ),
                ],
                const SizedBox(height: AppTokens.spaceSM),
                _buildSummaryLine(
                  'Phí vận chuyển:',
                  totals.shippingFee > 0
                      ? '+${_formatCurrency(totals.shippingFee)}'
                      : 'Miễn phí',
                  color: totals.shippingFee > 0
                      ? AppColors.textPrimary
                      : AppColors.success,
                ),

                if (_paymentMethod == 'b2b_contract') ...[
                  const Divider(height: 20, color: AppColors.border),
                  _buildSummaryLine(
                    'Đặt cọc trước (30%):',
                    _formatCurrency(totals.finalAmount * 0.3),
                    isBold: true,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: AppTokens.spaceXS),
                  _buildSummaryLine(
                    'Còn lại khi nhận hàng (70%):',
                    _formatCurrency(totals.finalAmount * 0.7),
                    color: AppColors.textSecondary,
                  ),
                ],

                const Divider(height: 20, color: AppColors.border),

                _buildSummaryLine(
                  'Tổng giá trị đơn hàng:',
                  _formatCurrency(totals.finalAmount),
                  isBold: true,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.space2XL),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: isBold ? 14 : fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.spaceSM),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: isBold ? fontSize : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return Material(
      color: isSelected ? AppColors.primaryTint : AppColors.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
          padding: const EdgeInsets.all(AppTokens.spaceMD),
          constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                ),
                child: Icon(icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22),
              ),
              const SizedBox(width: AppTokens.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
