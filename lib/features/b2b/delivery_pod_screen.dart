import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/milestone_timeline.dart';
import '../../data/models/delivery.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/order_repository.dart';

class DeliveryPoDScreen extends ConsumerStatefulWidget {
  final String? orderId;

  const DeliveryPoDScreen({super.key, this.orderId});

  @override
  ConsumerState<DeliveryPoDScreen> createState() => _DeliveryPoDScreenState();
}

class _DeliveryPoDScreenState extends ConsumerState<DeliveryPoDScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  DeliveryModel? _delivery;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDelivery();
    });
  }

  Future<void> _loadDelivery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(deliveryRepositoryProvider);
      DeliveryModel? foundDelivery;

      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        foundDelivery = await repo.getByOrder(widget.orderId!);
      }

      if (foundDelivery == null) {
        final all = await repo.getMyDeliveries();
        if (all.isNotEmpty) {
          foundDelivery = all.first;
        }
      }

      if (mounted) {
        setState(() {
          _delivery = foundDelivery;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleConfirmReceipt() async {
    if (_delivery == null) return;

    setState(() => _isSubmitting = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final targetId = _delivery!.orderId ?? _delivery!.id;

      await orderRepo.confirmDeliveryReceipt(targetId);

      // Verify associated proofs
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      for (final p in _delivery!.proofs) {
        if (!p.isVerified) {
          try {
            await deliveryRepo.verifyProof(p.id, isVerified: true, notes: 'Khách hàng xác nhận qua Mobile PoD');
          } catch (_) {}
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận nhận hàng thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadDelivery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa xác nhận được, bạn thử lại sau nhé: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showDisputeDialog() {
    if (_delivery == null) return;

    String selectedReason = 'Hàng bị móp méo / biến dạng do nhiệt độ';
    final notesController = TextEditingController();

    const reasons = [
      'Hàng bị móp méo / biến dạng do nhiệt độ',
      'Thiếu số lượng kiện hàng so với hợp đồng',
      'Tem niêm phong hộp bị rách / trầy xước',
      'Nhiệt độ xe lạnh vượt ngưỡng an toàn',
      'Lý do khác',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              ),
              title: const Row(
                children: [
                  Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Khiếu nại đơn hàng',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vui lòng chọn lý do khiếu nại:',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ...reasons.map((r) {
                      final isSelected = selectedReason == r;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedReason = r),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 18,
                                color: isSelected ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  r,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Mô tả chi tiết vấn đề *',
                        hintText: 'Nhập tình trạng hàng nhận được...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusInput)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textWhite,
                    minimumSize: const Size(120, AppTokens.minTapTarget),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    setState(() => _isSubmitting = true);
                    try {
                      final orderRepo = ref.read(orderRepositoryProvider);
                      final targetId = _delivery!.orderId ?? _delivery!.id;
                      await orderRepo.reportDispute(
                        targetId,
                        reason: selectedReason,
                        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi khiếu nại tới xưởng bánh để hỗ trợ bạn.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      _loadDelivery();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chưa gửi được khiếu nại, bạn thử lại sau nhé: ${e.toString().replaceFirst('Exception: ', '')}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
                  child: const Text('Gửi khiếu nại', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Phóng to ảnh chứng từ PoD với InteractiveViewer (Zoom/Pinch)
  void _showProofZoomModal(DeliveryProof proof) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceMD),
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proof.proofType,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chụp lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(proof.takenAt)}',
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Zoomable Image Container
            Container(
              color: Colors.black,
              constraints: const BoxConstraints(maxHeight: 420),
              child: ClipRect(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: proof.photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: proof.photoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const SizedBox(
                              height: 260,
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const SizedBox(
                              height: 260,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined, size: 54, color: AppColors.textMuted),
                              ),
                            ),
                          )
                        : const SizedBox(
                            height: 260,
                            child: Center(
                              child: Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.textMuted),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Modal Footer: Zoom guide & Notes
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.pinch_outlined, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        'Dùng 2 ngón tay để phóng to xem chi tiết ảnh',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (proof.notes != null && proof.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ghi chú tài xế: ${proof.notes}',
                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<MilestoneItem> _buildDeliveryMilestones(DeliveryModel d) {
    final status = d.status.toLowerCase();
    final isDispatched = status != 'created' && status != 'pending';
    final isInTransit = status == 'in_transit' ||
        status == 'delivering' ||
        status == 'delivered' ||
        status == 'completed';
    final isDelivered = status == 'delivered' || status == 'completed';
    final isCompleted = status == 'completed';

    return [
      MilestoneItem(
        title: 'Xuất xưởng',
        subtitle: 'Đóng gói bảo quản',
        status: isDispatched ? MilestoneStepStatus.completed : MilestoneStepStatus.current,
      ),
      MilestoneItem(
        title: 'Đang giao',
        subtitle: 'Bảo quản tiêu chuẩn',
        status: isInTransit
            ? (isDelivered ? MilestoneStepStatus.completed : MilestoneStepStatus.current)
            : MilestoneStepStatus.upcoming,
      ),
      MilestoneItem(
        title: 'Đến điểm nhận',
        subtitle: isDelivered ? 'Đã giao hàng' : 'Đang tới',
        status: isDelivered
            ? (isCompleted ? MilestoneStepStatus.completed : MilestoneStepStatus.current)
            : MilestoneStepStatus.upcoming,
      ),
      MilestoneItem(
        title: 'Xác nhận nhận hàng',
        subtitle: isCompleted ? 'Đã nhận đủ' : 'Chờ bạn xác nhận',
        status: isCompleted ? MilestoneStepStatus.completed : MilestoneStepStatus.upcoming,
      ),
    ];
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton.shimmer(
            child: Container(
              height: 120,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
            ),
          ),
          const SizedBox(height: AppTokens.spaceLG),
          AppSkeleton.shimmer(
            child: Container(
              height: 140,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
            ),
          ),
          const SizedBox(height: AppTokens.spaceLG),
          AppSkeleton.shimmer(
            child: Container(
              height: 220,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Theo dõi giao hàng', showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Chưa tải được thông tin giao hàng',
        message: _errorMessage!,
        onRetry: _loadDelivery,
        retryLabel: 'Thử lại ngay',
      );
    }

    if (_delivery == null) {
      return AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Chưa có chuyến giao hàng',
        message: 'Hiện tại bạn chưa có đơn hàng nào đang giao.',
        actionLabel: 'Tải lại',
        onAction: _loadDelivery,
      );
    }

    final d = _delivery!;
    final temp = d.coldChainTemp ?? 21.5;
    final isTempSafe = temp >= 18.0 && temp <= 25.0;
    final isCompleted = d.status.toLowerCase() == 'delivered' || d.status.toLowerCase() == 'completed';
    final trackingCode = d.trackingCode ?? d.deliveryNumber;

    final deliveryMilestones = _buildDeliveryMilestones(d);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDelivery,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Card (Sửa triệt để lỗi tràn 63px - bọc Column + Flexible, badge đặt dòng dưới)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mã vận đơn',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trackingCode,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  AppStatusChip(
                    status: d.status,
                    type: AppStatusType.delivery,
                    size: AppStatusChipSize.small,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 2. MilestoneTimeline (Tiến độ giao nhận)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timeline_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Tiến độ giao hàng',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  MilestoneTimeline(
                    items: deliveryMilestones,
                    orientation: Axis.horizontal,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 3. ColdChain Monitor Box (Giám sát nhiệt độ / độ ẩm xe lạnh)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: isTempSafe ? AppColors.infoBg : AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(
                  color: isTempSafe ? AppColors.info.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.ac_unit,
                        color: isTempSafe ? AppColors.info : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Theo dõi bảo quản bánh',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isTempSafe ? AppColors.info : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ColdChainMetric(
                        label: 'Nhiệt độ thùng xe',
                        value: '${temp.toStringAsFixed(1)}°C',
                        status: isTempSafe ? 'Đạt chuẩn (18-25°C)' : 'Vượt ngưỡng an toàn',
                        isSafe: isTempSafe,
                      ),
                      const _ColdChainMetric(
                        label: 'Độ ẩm thùng hàng',
                        value: '55%',
                        status: 'Đạt chuẩn bánh tươi',
                        isSafe: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 15, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đơn vị giao: ${d.carrierName ?? "Đội giao hàng Nguyệt Phố"}',
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Điểm giao: ${d.deliveryAddress ?? "Địa chỉ nhận hàng"}',
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 4. Proof of Delivery (PoD) Documents Card (Ảnh phóng to + 2 nút Xác nhận/Khiếu nại)
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border, width: 0.8),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hình ảnh giao nhận hàng',
                          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chạm vào ảnh để xem chi tiết kiện hàng và biên nhận của tài xế.',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),

                  // Display uploaded proofs from driver/carrier
                  if (d.proofs.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: d.proofs.length,
                      itemBuilder: (context, index) {
                        final proof = d.proofs[index];
                        return InkWell(
                          onTap: () => _showProofZoomModal(proof),
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusSM)),
                                        child: proof.photoUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: proof.photoUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) => const Icon(
                                                  Icons.image_outlined,
                                                  size: 32,
                                                  color: AppColors.textMuted,
                                                ),
                                              )
                                            : const Icon(Icons.receipt_outlined, size: 32, color: AppColors.textMuted),
                                      ),
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        proof.proofType,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        DateFormat('dd/MM HH:mm').format(proof.takenAt),
                                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 34, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'Đang chờ tài xế tải ảnh lên',
                              style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hình ảnh kiện hàng và biên nhận sẽ xuất hiện tại đây khi tài xế giao tới bạn.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTokens.spaceLG),

                  // 2 Nút Xác nhận / Khiếu nại (D18)
                  if (isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTokens.spaceMD),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã xác nhận nhận hàng thành công. Thông tin giao nhận đã được lưu trữ.',
                              style: TextStyle(fontFamily: 'Roboto', fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    CustomButton(
                      title: 'Xác nhận nhận hàng',
                      size: ButtonSize.large,
                      width: double.infinity,
                      loading: _isSubmitting,
                      disabled: _isSubmitting,
                      onPress: _handleConfirmReceipt,
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    CustomButton(
                      title: 'Khiếu nại đơn hàng',
                      variant: ButtonVariant.outline,
                      size: ButtonSize.medium,
                      width: double.infinity,
                      disabled: _isSubmitting,
                      onPress: _showDisputeDialog,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColdChainMetric extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final bool isSafe;

  const _ColdChainMetric({
    required this.label,
    required this.value,
    required this.status,
    required this.isSafe,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isSafe ? AppColors.success : AppColors.error;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isSafe ? AppColors.info : AppColors.error,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
        Text(status, style: TextStyle(fontFamily: 'Roboto', fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
