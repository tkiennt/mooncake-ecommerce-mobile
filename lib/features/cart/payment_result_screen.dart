// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/custom_button.dart';

class PaymentResultScreen extends ConsumerStatefulWidget {
  final bool isSuccess;
  final String orderCode;

  const PaymentResultScreen({
    super.key,
    this.isSuccess = true,
    this.orderCode = 'DH-2026-9921',
  });

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _isLoading = true;
  String? _error;
  Order? _order;

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
    });
  }

  Future<void> _loadOrderDetails() async {
    if (widget.orderCode.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final orders = await orderRepo.getMyOrders();

      final matched = orders.firstWhere(
        (o) => o.orderCode.toLowerCase() == widget.orderCode.toLowerCase(),
        orElse: () => Order(
          id: '',
          orderCode: widget.orderCode,
          status: widget.isSuccess ? 'confirmed' : 'pending_payment',
          totalAmount: 0,
          finalAmount: 0,
          discountAmount: 0,
          subtotal: 0,
          shippingFee: 0,
          taxAmount: 0,
          packagingFee: 0,
          shippingAddress: '',
          recipientName: '',
          recipientPhone: '',
          createdAt: DateTime.now(),
        ),
      );

      if (matched.id.isNotEmpty) {
        try {
          final detail = await orderRepo.getOrderDetails(matched.id);
          if (mounted) {
            setState(() {
              _order = detail;
              _isLoading = false;
            });
          }
          return;
        } catch (_) {
          // Fall back to matched order summary
        }
      }

      if (mounted) {
        setState(() {
          _order = matched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể đồng bộ chi tiết đơn hàng: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Kết Quả Thanh Toán',
        showBack: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. Loading state with AppSkeleton
    if (_isLoading) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.space2XL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppSkeleton.circle(radius: 36),
              const SizedBox(height: AppTokens.spaceLG),
              const AppSkeleton.text(width: 220, height: 18),
              const SizedBox(height: AppTokens.spaceMD),
              const AppSkeleton.text(width: 280, height: 14),
              const SizedBox(height: AppTokens.spaceXL),
              AppSkeleton.orderCard(),
              const SizedBox(height: AppTokens.spaceXL),
              const AppSkeleton(width: double.infinity, height: 48),
            ],
          ),
        ),
      );
    }

    // 2. Error state with AppErrorState
    if (_error != null && _order == null) {
      return AppErrorState(
        title: 'Lỗi đồng bộ kết quả',
        message: _error,
        onRetry: _loadOrderDetails,
        retryLabel: 'Thử lại',
        secondaryActionLabel: 'Về trang chủ',
        onSecondaryAction: () => context.go('/'),
      );
    }

    // 3. Empty state with AppEmptyState
    if (widget.orderCode.isEmpty && _order == null) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Không tìm thấy thông tin đơn hàng',
        message:
            'Mã đơn hàng không hợp lệ hoặc thông tin giao dịch chưa được lưu lại trong hệ thống.',
        actionLabel: 'Xem danh sách đơn',
        onAction: () => context.go('/orders'),
        secondaryActionLabel: 'Về trang chủ',
        onSecondaryAction: () => context.go('/'),
      );
    }

    final isSuccess = widget.isSuccess;
    final displayOrderCode =
        _order?.orderCode.isNotEmpty == true ? _order!.orderCode : widget.orderCode;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Icon Container
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.successBg : AppColors.errorBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isSuccess ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  size: 44,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // Status Title
            Text(
              isSuccess
                  ? 'Đặt Cọc / Thanh Toán Thành Công!'
                  : 'Giao Dịch Chưa Thành Công',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spaceSM),

            // Status Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
              child: Text(
                isSuccess
                    ? 'Đơn hàng mã $displayOrderCode đã được ghi nhận vào hệ thống sản xuất. Xưởng sẽ chuẩn bị nguyên liệu và giao theo tiến độ thỏa thuận.'
                    : 'Giao dịch thanh toán chưa thể hoàn tất. Đơn hàng mã $displayOrderCode của bạn vẫn được lưu lại để có thể tiếp tục thanh toán.',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXL),

            // Order Information Card (Dữ liệu từ repository thật)
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
                      const Text(
                        'Mã đơn hàng:',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        displayOrderCode,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trạng thái đơn:',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppStatusChip(
                        status: _order?.status ??
                            (isSuccess ? 'confirmed' : 'pending_payment'),
                        type: AppStatusType.order,
                        size: AppStatusChipSize.small,
                      ),
                    ],
                  ),
                  if (_order != null && _order!.finalAmount > 0) ...[
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thanh toán:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(_order!.finalAmount),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_order != null && _order!.recipientName.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spaceSM),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Người nhận:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSM),
                        Expanded(
                          child: Text(
                            '${_order!.recipientName}${_order!.recipientPhone.isNotEmpty ? ' (${_order!.recipientPhone})' : ''}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_order != null && _order!.shippingAddress.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spaceSM),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Địa chỉ nhận:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSM),
                        Expanded(
                          child: Text(
                            _order!.shippingAddress,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTokens.space2XL),

            // Next Actions (Hành động tiếp theo, CTA >= 48px)
            if (isSuccess) ...[
              CustomButton(
                title: 'Theo dõi tiến độ đơn hàng',
                icon: const Icon(Icons.local_shipping_outlined,
                    size: 20, color: AppColors.textWhite),
                size: ButtonSize.large, // >= 48px
                width: double.infinity,
                onPress: () => context.go('/orders'),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              CustomButton(
                title: 'Tiếp tục mua hàng',
                icon: const Icon(Icons.shopping_bag_outlined,
                    size: 20, color: AppColors.primary),
                variant: ButtonVariant.outline,
                size: ButtonSize.large, // >= 48px
                width: double.infinity,
                onPress: () => context.go('/search'),
              ),
              const SizedBox(height: AppTokens.spaceSM),
              TextButton(
                onPressed: () => context.go('/'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                ),
                child: const Text(
                  'Về trang chủ',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ] else ...[
              CustomButton(
                title: 'Thử thanh toán lại',
                icon: const Icon(Icons.refresh,
                    size: 20, color: AppColors.textWhite),
                size: ButtonSize.large, // >= 48px
                width: double.infinity,
                onPress: () => context.push('/checkout'),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              CustomButton(
                title: 'Kiểm tra giỏ hàng',
                icon: const Icon(Icons.shopping_cart_outlined,
                    size: 20, color: AppColors.primary),
                variant: ButtonVariant.outline,
                size: ButtonSize.large, // >= 48px
                width: double.infinity,
                onPress: () => context.go('/cart'),
              ),
              const SizedBox(height: AppTokens.spaceSM),
              TextButton(
                onPressed: () => context.go('/'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                ),
                child: const Text(
                  'Về trang chủ',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
