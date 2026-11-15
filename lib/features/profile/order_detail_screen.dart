import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/antd/antd_steps.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Order _order;
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details =
          await ref.read(orderRepositoryProvider).getOrderDetails(_order.id);
      if (mounted) {
        setState(() {
          _order = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Xác nhận hủy đơn hàng',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn hàng ${_order.orderCode} không? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đơn hàng'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(
            _order.id,
            reason: 'Khách hàng yêu cầu hủy trên ứng dụng di động',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi yêu cầu hủy đơn hàng thành công.'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể hủy đơn hàng: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _handleConfirmReceipt() async {
    setState(() => _isActionInProgress = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .confirmDeliveryReceipt(_order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận nhận hàng và nghiệm thu thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchOrderDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xác nhận nhận hàng: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  int _calculateStep(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'processing':
      case 'in_production':
      case 'inproduction':
        return 1;
      case 'shipping':
      case 'shipped':
      case 'delivering':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      case 'pending':
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _order.status.toLowerCase() == 'cancelled';
    final isPending = _order.status.toLowerCase() == 'pending';
    final isShipping = [
      'shipping',
      'shipped',
      'delivering'
    ].contains(_order.status.toLowerCase());

    return Scaffold(
      appBar: AppHeader(
        title: 'Chi Tiết ${_order.orderCode}',
        showBack: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchOrderDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Không thể đồng bộ dữ liệu mới nhất: $_errorMessage',
                          style: const TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppColors.error),
                        onPressed: _fetchOrderDetails,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              if (isCancelled)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đơn hàng này đã bị hủy.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tiến Trình Đơn Hàng',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AntdSteps(
                      current: _calculateStep(_order.status),
                      items: const [
                        StepItemData(title: 'Đặt hàng', desc: 'Đã xác nhận'),
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
                    const Text(
                      'Danh Sách Sản Phẩm',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ..._order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: item.imageUrl != null &&
                                        item.imageUrl!.startsWith('http')
                                    ? Image.network(
                                        item.imageUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/products/banh-nuong.jpg',
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        item.imageUrl ??
                                            'assets/products/banh-nuong.jpg',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
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
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    if (item.variantName != null &&
                                        item.variantName!.isNotEmpty)
                                      Text(
                                        'Biến thể: ${item.variantName}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    Text(
                                      'Số lượng: ${item.quantity} hộp',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatCurrency(item.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
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
                    const Text(
                      'Thông Tin Nhận Hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Người nhận: ${_order.recipientName} (${_order.recipientPhone})',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Địa chỉ: ${_order.shippingAddress}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (_order.deliveryNote != null &&
                        _order.deliveryNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ghi chú: ${_order.deliveryNote}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
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
                    _row('Tổng tiền hàng:', _formatCurrency(_order.totalAmount)),
                    const SizedBox(height: 6),
                    _row(
                      'Chiết khấu doanh nghiệp:',
                      '-${_formatCurrency(_order.discountAmount)}',
                      color: AppColors.success,
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    _row(
                      'Tổng thanh toán:',
                      _formatCurrency(_order.finalAmount),
                      isBold: true,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (isPending)
                OutlinedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleCancelOrder,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(_isActionInProgress
                      ? 'Đang xử lý...'
                      : 'Hủy đơn hàng này'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                  ),
                ),

              if (isShipping)
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _handleConfirmReceipt,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(_isActionInProgress
                      ? 'Đang xác nhận...'
                      : 'Xác nhận đã nhận hàng (PoD)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14.5 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
