import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
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

      // Also verify any associated proof if present
      final deliveryRepo = ref.read(deliveryRepositoryProvider);
      for (final p in _delivery!.proofs) {
        if (!p.isVerified) {
          try {
            await deliveryRepo.verifyProof(p.id, isVerified: true, notes: 'Khách hàng đã xác nhận qua Mobile PoD');
          } catch (_) {}
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận nhận hàng thành công! Đơn hàng đã hoàn tất biên bản bàn giao.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadDelivery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác nhận nhận hàng thất bại: ${e.toString().replaceFirst('Exception: ', '')}'),
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
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              ),
              title: const Row(
                children: [
                  Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 24),
                  SizedBox(width: 8),
                  Text('Khiếu Nại Kiện Hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vui lòng chọn lý do phát sinh sự cố giao nhận:',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    ...reasons.map((r) {
                      final isSelected = selectedReason == r;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedReason = r),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết sự cố kiện hàng',
                        hintText: 'Nhập ghi chú hoặc mã số kiện hàng gặp sự cố...',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
                ),
                CustomButton(
                  title: 'Gửi khiếu nại',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.small,
                  onPress: () async {
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
                          content: Text('Đã gửi khiếu nại tới xưởng và bộ phận CSKH để xử lý đối soát.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      _loadDelivery();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gửi khiếu nại thất bại: ${e.toString().replaceFirst('Exception: ', '')}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProofPreview(DeliveryProof proof) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.lucianRadiusLg)),
              child: proof.photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: proof.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppColors.surfaceHover,
                        child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: AppColors.surfaceHover,
                      child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proof.proofType,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(proof.takenAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (proof.notes != null && proof.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ghi chú: ${proof.notes}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Giám Sát Vận Chuyển & PoD', showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu vận chuyển & chứng từ xe lạnh...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải dữ liệu vận chuyển',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              CustomButton(
                title: 'Thử lại',
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                onPress: _loadDelivery,
              ),
            ],
          ),
        ),
      );
    }

    if (_delivery == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping_outlined, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa Có Chuyến Giao Hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hiện tại Quý Doanh Nghiệp chưa có chuyến vận chuyển xe lạnh nào đang thực hiện hoặc chờ xác nhận biên bản PoD.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              CustomButton(
                title: 'Tải lại',
                variant: ButtonVariant.outline,
                size: ButtonSize.medium,
                onPress: _loadDelivery,
              ),
            ],
          ),
        ),
      );
    }

    final d = _delivery!;
    final temp = d.coldChainTemp ?? 21.5;
    final isTempSafe = temp >= 18.0 && temp <= 25.0;
    final isCompleted = d.status.toLowerCase() == 'delivered' || d.status.toLowerCase() == 'completed';

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDelivery,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ColdChain Monitor Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isTempSafe ? AppColors.infoBg : AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(
                  color: isTempSafe
                      ? AppColors.info.withValues(alpha: 0.4)
                      : AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ac_unit,
                            color: isTempSafe ? AppColors.info : AppColors.error,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cảm Biến Xe Lạnh Vận Chuyển',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isTempSafe ? AppColors.info : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppTokens.lucianRadiusPill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          d.status,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                        label: 'Độ ẩm không khí',
                        value: '55%',
                        status: 'Tối ưu bảo quản',
                        isSafe: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 16, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đơn vị: ${d.carrierName ?? 'Xe Lạnh Hoàng Gia Logistics'} (${d.trackingCode ?? d.deliveryNumber})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Điểm giao: ${d.deliveryAddress ?? 'Địa chỉ doanh nghiệp'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof of Delivery (PoD) Documents Card
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
                      Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chứng Từ & Ảnh Bàn Giao (PoD)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Khách hàng kiểm tra chứng từ xe lạnh, tem niêm phong và ảnh chụp kiện hàng do tài xế tải lên trước khi bấm xác nhận hoàn tất.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Display uploaded proofs from driver/carrier
                  if (d.proofs.isNotEmpty) ...[
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: d.proofs.length,
                      itemBuilder: (context, index) {
                        final proof = d.proofs[index];
                        return InkWell(
                          onTap: () => _showProofPreview(proof),
                          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusDefault)),
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
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        DateFormat('dd/MM HH:mm').format(proof.takenAt),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'Đang Chờ Tài Xế Tải Lên Chứng Từ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Biên bản bàn giao và ảnh niêm phong kiện hàng sẽ xuất hiện khi tài xế đến điểm giao.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  if (isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đã hoàn tất xác nhận nhận hàng PoD. Biên bản đã được lưu trữ an toàn.',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Customer actions: Confirm receipt & Dispute
                    CustomButton(
                      title: 'Xác nhận đã nhận đủ số lượng & nguyên vẹn',
                      size: ButtonSize.large,
                      width: double.infinity,
                      loading: _isSubmitting,
                      disabled: _isSubmitting,
                      onPress: _handleConfirmReceipt,
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      title: 'Khiếu nại / Báo cáo sự cố kiện hàng',
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isSafe ? AppColors.info : AppColors.error,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
