// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_price_tag.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/quantity_b2b_stepper.dart';
import '../../shared_widgets/common/sticky_bottom_bar.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _isInitialSyncing = false;
  String? _syncError;

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQuote();
    });
  }

  Future<void> _syncQuote() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    setState(() {
      _isInitialSyncing = true;
      _syncError = null;
    });

    try {
      await ref
          .read(cartProvider.notifier)
          .syncServerQuote(ref.read(apiClientProvider));
      if (mounted) {
        setState(() {
          _isInitialSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialSyncing = false;
          _syncError = 'Không thể đồng bộ bảng giá chiết khấu: $e';
        });
      }
    }
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
      body: _buildBody(cartState),
      bottomNavigationBar: cartState.items.isNotEmpty
          ? StickyBottomBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng thanh toán (${totals.totalItems} hộp)',
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
                          price: totals.finalAmount,
                          size: AppPriceTagSize.medium,
                          isBold: true,
                        ),
                        if (totals.discountAmount > 0) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Tiết kiệm: -${_formatCurrency(totals.discountAmount)}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
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
                    title: 'Thanh toán',
                    size: ButtonSize.large, // CTA >= 48px
                    onPress: () => context.push('/checkout'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBody(CartState cartState) {
    // 1. Loading state with AppSkeleton
    if (_isInitialSyncing && cartState.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          children: [
            AppSkeleton.orderCard(),
            const SizedBox(height: AppTokens.spaceMD),
            AppSkeleton.orderCard(),
          ],
        ),
      );
    }

    // 2. Error state with AppErrorState
    if (_syncError != null && cartState.items.isEmpty) {
      return AppErrorState(
        title: 'Lỗi tải giỏ hàng',
        message: _syncError,
        onRetry: _syncQuote,
        retryLabel: 'Thử lại',
      );
    }

    // 3. Empty state with AppEmptyState
    if (cartState.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.remove_shopping_cart_outlined,
        title: 'Giỏ hàng của bạn đang trống',
        message:
            'Khám phá ngay các bộ sưu tập bánh trung thu cao cấp để chọn món quà doanh nghiệp ý nghĩa.',
        actionLabel: 'Khám phá sản phẩm',
        onAction: () => context.go('/search'),
      );
    }

    // 4. Cart Content
    final totals = cartState.totals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Non-blocking sync error notification banner
          if (_syncError != null)
            Container(
              margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: AppTokens.spaceSM),
                  Expanded(
                    child: Text(
                      _syncError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20, color: AppColors.error),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: _syncQuote,
                  ),
                ],
              ),
            ),

          // List of Cart Items
          ...cartState.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppTokens.elevationSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Item Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                        child: item.product.coverImage != null &&
                                item.product.coverImage!.startsWith('http')
                            ? Image.network(
                                item.product.coverImage!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/products/banh-nuong.jpg',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                item.product.coverImage ??
                                    'assets/products/banh-nuong.jpg',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.surfaceHover,
                                  child: const Icon(Icons.cake_outlined,
                                      color: AppColors.primary),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppTokens.spaceMD),

                      // Name, Variant, Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.variant != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Quy cách: ${item.variant!.name}',
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            AppPriceTag(
                              price: item.unitPrice,
                              size: AppPriceTagSize.small,
                              isBold: true,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Thành tiền: ${_formatCurrency(item.subtotal)}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Delete Button (tap target >= 44px)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 22, color: AppColors.error),
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ref
                              .read(cartProvider.notifier)
                              .removeFromCart(item.product.id, item.variant?.id);
                          _syncQuote();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTokens.spaceMD),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppTokens.spaceMD),

                  // B2B Stepper (D14: +/- + chip mốc 50/100/200/500 + nhập tự do)
                  Row(
                    children: [
                      const Text(
                        'Số lượng đặt:',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      if (cartState.isCalculatingQuote)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  QuantityB2BStepper(
                    value: item.quantity,
                    min: 1,
                    max: 50000,
                    step: 1,
                    quickTiers: const [50, 100, 200, 500],
                    showQuickChips: true,
                    unit: 'hộp',
                    onChanged: (newQty) {
                      ref.read(cartProvider.notifier).updateQuantity(
                            item.product.id,
                            item.variant?.id,
                            newQty,
                          );
                      _syncQuote();
                    },
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppTokens.spaceSM),

          // Coupon Section
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cartState.appliedCoupon != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: AppTokens.spaceSM),
                      Expanded(
                        child: Text(
                          'Mã giảm giá: ${cartState.appliedCoupon} (-${cartState.couponDiscountPercent.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).removeCoupon();
                          _couponController.clear();
                          _syncQuote();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                        ),
                        child: const Text(
                          'Gỡ mã',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã giảm giá (ví dụ: B2BMOON2026)',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppTokens.spaceMD,
                              vertical: AppTokens.spaceSM + 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      CustomButton(
                        title: 'Áp dụng',
                        size: ButtonSize.medium,
                        onPress: () {
                          final code = _couponController.text.trim();
                          if (code.isNotEmpty) {
                            ref.read(cartProvider.notifier).applyCoupon(code);
                            _syncQuote();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mã giảm giá đã được áp dụng!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spaceLG),

          // Price Breakdown Summary Card (Tóm tắt đơn rõ ràng)
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
                    Icon(Icons.receipt_long_outlined,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: AppTokens.spaceSM),
                    Text(
                      'Tóm tắt chi phí đơn hàng',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spaceMD),
                _buildSummaryRow(
                  'Tạm tính (${totals.totalItems} hộp):',
                  _formatCurrency(totals.subtotal),
                ),
                if (totals.discountAmount > 0) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryRow(
                    'Chiết khấu bậc thang & mã:',
                    '-${_formatCurrency(totals.discountAmount)}',
                    isHighlight: true,
                  ),
                ],
                if (totals.taxAmount > 0) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryRow(
                    'Thuế VAT (8%):',
                    '+${_formatCurrency(totals.taxAmount)}',
                  ),
                ],
                if (totals.shippingFee > 0) ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryRow(
                    'Phí vận chuyển xe lạnh:',
                    '+${_formatCurrency(totals.shippingFee)}',
                  ),
                ] else ...[
                  const SizedBox(height: AppTokens.spaceSM),
                  _buildSummaryRow(
                    'Phí vận chuyển:',
                    'Miễn phí',
                    color: AppColors.success,
                  ),
                ],
                const Divider(height: 24, color: AppColors.border),
                _buildSummaryRow(
                  'Tổng thanh toán:',
                  _formatCurrency(totals.finalAmount),
                  isBold: true,
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

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isHighlight = false,
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
              fontSize: isBold ? 14.5 : 13,
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
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ??
                (isHighlight ? AppColors.success : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
