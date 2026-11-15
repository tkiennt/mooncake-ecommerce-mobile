import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/custom_packaging.dart';
import '../../data/models/delivery.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/custom_packaging_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/milestone_timeline.dart';
import 'widgets/auto_confirm_banner.dart';
import 'widgets/custom_packaging_review_card.dart';
import 'widgets/delivery_driver_info_card.dart';
import 'widgets/order_dispute_rebuttal_card.dart';

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
  CustomPackagingModel? _customPackaging;
  DeliveryModel? _delivery;

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

    // Load custom packaging if applicable
    try {
      final packagingRepo = ref.read(customPackagingRepositoryProvider);
      final pkg = await packagingRepo.getCustomPackaging(_order.id);
      if (mounted) setState(() => _customPackaging = pkg);
    } catch (_) {}

    // Load delivery info if applicable
    try {
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      final d = await deliveryRepo.getByOrder(_order.id);
      if (mounted) setState(() => _delivery = d);
    } catch (_) {}
  }

  Future<void> _handleCancelOrder() async {
    final status = _order.status.toLowerCase();
    final isInProduction = ['processing', 'in_production', 'inproduction'].contains(status);
    final hasCustom = _customPackaging != null || _order.isBulkOrder;
    final suggestedPercent = isInProduction ? (hasCustom ? 50 : 100) : 100;
    final suggestedRefund = _order.finalAmount * (suggestedPercent / 100);

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text(
              'Xác nhận hủy đơn hàng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn gửi yêu cầu hủy đơn hàng ${_order.orderCode} không?',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  border: Border.all(color: AppColors.warning, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chính sách hoàn tiền (D24):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isInProduction && hasCustom
                          ? '• Đơn hàng đang sản xuất & có bao bì/in ấn riêng: Đề xuất hoàn 50% (${_formatCurrency(suggestedRefund)}) do chi phí khuôn in và vật tư đã chuẩn bị.'
                          : '• Đơn hàng chưa vào khuôn sản xuất riêng: Đề xuất hoàn trả 100% (${_formatCurrency(suggestedRefund)}).',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Lý do hủy đơn *',
                  hintText: 'Nhập lý do hủy...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final reason = reasonController.text.trim().isNotEmpty
        ? reasonController.text.trim()
        : 'Khách hàng yêu cầu hủy trên ứng dụng di động';

    setState(() => _isActionInProgress = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(
            _order.id,
            reason: reason,
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

  void _handleReorder() {
    if (_order.items.isEmpty) return;
    for (final item in _order.items) {
      final prod = Product(
        id: item.productId.isNotEmpty ? item.productId : item.id,
        name: item.productName,
        basePrice: item.unitPrice,
        coverImage: item.imageUrl,
        shopId: _order.shopId,
        shopName: _order.shopName ?? 'Nguyệt Phố B2B',
      );
      final variant = item.variantId != null && item.variantId!.isNotEmpty
          ? ProductVariant(id: item.variantId!, name: item.variantName ?? '')
          : null;
      ref.read(cartProvider.notifier).addToCart(prod, variant, item.quantity);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${_order.items.length} món từ đơn ${_order.orderCode} vào giỏ hàng.'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'Xem giỏ hàng',
          textColor: Colors.white,
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  List<MilestoneItem> _buildMilestones() {
    final status = _order.status.toLowerCase();
    final isCancelled = status == 'cancelled';

    if (isCancelled) {
      return const [
        MilestoneItem(
          title: 'Đặt hàng',
          subtitle: 'Đã gửi yêu cầu',
          status: MilestoneStepStatus.completed,
          icon: Icons.receipt_long,
        ),
        MilestoneItem(
          title: 'Đã hủy',
          subtitle: 'Đã kết thúc',
          status: MilestoneStepStatus.failed,
          icon: Icons.cancel_outlined,
        ),
      ];
    }

    int currentStep = 0;
    if (['confirmed', 'processing', 'in_production', 'inproduction'].contains(status)) {
      currentStep = 1;
    } else if (['shipping', 'shipped', 'delivering', 'intransit', 'in_transit'].contains(status)) {
      currentStep = 2;
    } else if (['delivered', 'completed'].contains(status)) {
      currentStep = 3;
    }

    MilestoneStepStatus getStatus(int stepIndex) {
      if (stepIndex < currentStep) return MilestoneStepStatus.completed;
      if (stepIndex == currentStep) return MilestoneStepStatus.current;
      return MilestoneStepStatus.upcoming;
    }

    return [
      MilestoneItem(
        title: 'Đặt hàng',
        subtitle: 'Đã xác nhận',
        status: getStatus(0),
        icon: Icons.receipt_long,
      ),
      MilestoneItem(
        title: 'Sản xuất',
        subtitle: 'Xưởng làm bánh',
        status: getStatus(1),
        icon: Icons.precision_manufacturing,
      ),
      MilestoneItem(
        title: 'Giao hàng',
        subtitle: 'Xe lạnh 18-22°C',
        status: getStatus(2),
        icon: Icons.local_shipping,
      ),
      MilestoneItem(
        title: 'Nghiệm thu',
        subtitle: 'Ký nhận PoD',
        status: getStatus(3),
        icon: Icons.task_alt,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _order.items.isEmpty) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Chi Tiết ${_order.orderCode}',
          showBack: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          children: [
            AppSkeleton.orderCard(),
            const SizedBox(height: AppTokens.spaceLG),
            AppSkeleton.orderCard(),
          ],
        ),
      );
    }

    if (_errorMessage != null && _order.items.isEmpty) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Chi Tiết ${_order.orderCode}',
          showBack: true,
        ),
        body: AppErrorState(
          title: 'Không thể tải chi tiết đơn hàng',
          message: _errorMessage,
          retryLabel: 'Thử lại',
          onRetry: _fetchOrderDetails,
        ),
      );
    }

    final statusLower = _order.status.toLowerCase();
    final isPending = statusLower == 'pending';
    final isInProduction = ['processing', 'in_production', 'inproduction'].contains(statusLower);
    final canCancel = (isPending || isInProduction) &&
        !_order.isCancelled &&
        _order.pendingCancellationRequest == null;
    final isShipping = [
      'shipping',
      'shipped',
      'delivering',
      'intransit',
      'in_transit'
    ].contains(statusLower);

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
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: AppTokens.spaceSM),
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
                        constraints: const BoxConstraints(minWidth: AppTokens.minTapTarget, minHeight: AppTokens.minTapTarget),
                      ),
                    ],
                  ),
                ),

              // Auto Confirm 72h SLA Banner (D23)
              if (_order.isAutoConfirmActive || _order.autoConfirmAt != null) ...[
                AutoConfirmBanner(
                  deadline: _order.autoConfirmAt!,
                  orderCode: _order.orderCode,
                  onConfirmReceipt: _handleConfirmReceipt,
                ),
                const SizedBox(height: AppTokens.spaceMD),
              ],

              // Pending Cancellation Request Banner (D24)
              if (_order.pendingCancellationRequest != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                  padding: const EdgeInsets.all(AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppColors.warning, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top, color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Đang xử lý yêu cầu hủy đơn hàng',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.warning),
                            ),
                            child: Text(
                              '${_order.pendingCancellationRequest!.suggestedRefundPercent?.toInt() ?? 100}% Hoàn tiền',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đề xuất hoàn trả: ${_formatCurrency(_order.pendingCancellationRequest!.suggestedRefundAmount ?? _order.finalAmount)}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_order.pendingCancellationRequest!.suggestionReason != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _order.pendingCancellationRequest!.suggestionReason!,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Dispute & Supplier Rebuttal Card (D27)
              if (_order.activeDispute != null) ...[
                OrderDisputeRebuttalCard(
                  dispute: _order.activeDispute!,
                ),
                const SizedBox(height: AppTokens.spaceMD),
              ],

              // Header Status Card
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                margin: const EdgeInsets.only(bottom: AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order.orderCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(_order.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceSM),
                    AppStatusChip(
                      status: _order.status,
                      type: AppStatusType.order,
                    ),
                  ],
                ),
              ),

              // Milestone Timeline Card (Theo yêu cầu task)
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
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
                    const SizedBox(height: AppTokens.spaceMD),
                    MilestoneTimeline(
                      items: _buildMilestones(),
                      orientation: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSM),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // Custom Packaging Mockup Review (D25)
              if (_customPackaging != null) ...[
                CustomPackagingReviewCard(
                  packaging: _customPackaging!,
                  onApprove: (revisionId) async {
                    setState(() => _isActionInProgress = true);
                    try {
                      await ref.read(customPackagingRepositoryProvider).reviewRevision(
                            _order.id,
                            revisionId,
                            action: 'Approve',
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã phê duyệt thiết kế bao bì thành công!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _fetchOrderDetails();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                      );
                    } finally {
                      if (mounted) setState(() => _isActionInProgress = false);
                    }
                  },
                  onRequestRevision: (revisionId, notes) async {
                    setState(() => _isActionInProgress = true);
                    try {
                      await ref.read(customPackagingRepositoryProvider).reviewRevision(
                            _order.id,
                            revisionId,
                            action: 'RequestRevision',
                            notes: notes,
                          );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi yêu cầu chỉnh sửa thiết kế tới xưởng.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      _fetchOrderDetails();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                      );
                    } finally {
                      if (mounted) setState(() => _isActionInProgress = false);
                    }
                  },
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Driver Info Card (D33)
              if (_delivery != null) ...[
                DeliveryDriverInfoCard(
                  driverName: _delivery!.driverName,
                  driverPhone: _delivery!.driverPhone,
                  vehiclePlate: _delivery!.vehiclePlate,
                  driverClaimedAt: _delivery!.driverClaimedAt,
                  trackingCode: _delivery!.trackingCode,
                  deliveryNumber: _delivery!.deliveryNumber,
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // Order Items
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh Sách Sản Phẩm',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    ..._order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                                child: item.imageUrl != null &&
                                        item.imageUrl!.startsWith('http')
                                    ? Image.network(
                                        item.imageUrl!,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Image.asset(
                                          'assets/products/banh-nuong.jpg',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        item.imageUrl ??
                                            'assets/products/banh-nuong.jpg',
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          color: AppColors.background,
                                          child: const Icon(Icons.cake,
                                              color: AppColors.primary),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: AppTokens.spaceMD),
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.variantName != null &&
                                        item.variantName!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Biến thể: ${item.variantName}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
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
                              const SizedBox(width: AppTokens.spaceSM),
                              Text(
                                _formatCurrency(item.totalPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // Shipping & Recipient Details
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông Tin Nhận Hàng',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: AppTokens.spaceSM),
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
              const SizedBox(height: AppTokens.spaceLG),

              // Financial Summary
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
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
              const SizedBox(height: AppTokens.spaceLG),

              // Action Buttons
              if (canCancel)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                  child: OutlinedButton.icon(
                    onPressed: _isActionInProgress ? null : _handleCancelOrder,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(_isActionInProgress
                        ? 'Đang xử lý...'
                        : (isPending ? 'Hủy đơn hàng này' : 'Yêu cầu hủy đơn hàng (hoàn tiền)')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                      ),
                    ),
                  ),
                ),

              if (isShipping)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                  child: ElevatedButton.icon(
                    onPressed: _isActionInProgress ? null : _handleConfirmReceipt,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_isActionInProgress
                        ? 'Đang xác nhận...'
                        : 'Xác nhận đã nhận hàng (PoD)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                      ),
                    ),
                  ),
                ),

              // Nút đặt lại đơn cũ (thêm vào giỏ hàng)
              ElevatedButton.icon(
                onPressed: _handleReorder,
                icon: const Icon(Icons.replay_outlined, size: 18),
                label: const Text('Đặt lại đơn hàng này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2XL),
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
