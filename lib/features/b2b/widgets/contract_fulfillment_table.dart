import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/delivery.dart';
import '../../../data/repositories/contract_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../profile/widgets/delivery_driver_info_card.dart';

class ContractFulfillmentTable extends ConsumerStatefulWidget {
  final String contractId;
  final String contractNumber;

  const ContractFulfillmentTable({
    super.key,
    required this.contractId,
    required this.contractNumber,
  });

  @override
  ConsumerState<ContractFulfillmentTable> createState() =>
      _ContractFulfillmentTableState();
}

class _ContractFulfillmentTableState
    extends ConsumerState<ContractFulfillmentTable> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ContractFulfillmentLine> _fulfillmentLines = [];
  List<DeliveryModel> _deliveries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contractRepo = ref.read(contractRepositoryProvider);
      final deliveryRepo = ref.read(deliveryRepositoryProvider);

      final results = await Future.wait([
        contractRepo.getContractFulfillment(widget.contractId).catchError((_) => <ContractFulfillmentLine>[]),
        deliveryRepo.getDeliveriesByContract(widget.contractId).catchError((_) => <DeliveryModel>[]),
      ]);

      if (mounted) {
        setState(() {
          _fulfillmentLines = results[0] as List<ContractFulfillmentLine>;
          _deliveries = results[1] as List<DeliveryModel>;
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

  void _showPoDProofsModal(DeliveryModel delivery) async {
    List<DeliveryProof> proofs = delivery.proofs;

    if (proofs.isEmpty) {
      try {
        final deliveryRepo = ref.read(deliveryRepositoryProvider);
        proofs = await deliveryRepo.getDeliveryProofs(delivery.id);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ảnh Chứng Từ PoD · ${delivery.deliveryNumber}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 16, color: AppColors.border),
              if (proofs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Chưa có ảnh chứng từ PoD nào cho đợt giao này.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: proofs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMD),
                    itemBuilder: (context, idx) {
                      final p = proofs[idx];
                      return Container(
                        padding: const EdgeInsets.all(AppTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTint,
                                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                  ),
                                  child: Text(
                                    p.proofType,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm dd/MM/yyyy').format(p.takenAt),
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (p.photoUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                child: Image.network(
                                  p.photoUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 120,
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image, size: 36, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            if (p.notes != null && p.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Ghi chú: ${p.notes}',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(AppTokens.spaceMD),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
        ),
        child: Text('Lỗi tải đối soát: $_errorMessage', style: const TextStyle(color: AppColors.error)),
      );
    }

    final totalContractQty = _fulfillmentLines.fold<int>(0, (acc, line) => acc + line.totalQuantity);
    final totalDeliveredQty = _fulfillmentLines.fold<int>(0, (acc, line) => acc + line.deliveredQuantity);
    final totalRemainingQty = _fulfillmentLines.fold<int>(0, (acc, line) => acc + line.remainingQuantity);
    final percent = totalContractQty > 0 ? ((totalDeliveredQty / totalContractQty) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Card
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
                  const Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Đối Soát Giao Hàng Theo Đợt',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$percent% hoàn tất',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                child: LinearProgressIndicator(
                  value: totalContractQty > 0 ? (totalDeliveredQty / totalContractQty).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Tổng số lượng', '$totalContractQty', AppColors.textPrimary),
                  _statItem('Đã giao', '$totalDeliveredQty', AppColors.success),
                  _statItem('Còn lại', '$totalRemainingQty', totalRemainingQty > 0 ? AppColors.warning : AppColors.textMuted),
                ],
              ),
              if (_fulfillmentLines.isNotEmpty) ...[
                const Divider(height: 24, color: AppColors.border),
                const Text(
                  'Chi tiết từng dòng sản phẩm:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ..._fulfillmentLines.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${line.productName}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Đã giao: ${line.deliveredQuantity}/${line.totalQuantity} (Còn ${line.remainingQuantity})',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceLG),

        // Deliveries by batch list
        const Text(
          'Danh Sách Các Đợt Giao Hàng',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTokens.spaceSM),
        if (_deliveries.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceLG),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Chưa có chuyến giao hàng nào được khởi tạo cho hợp đồng này.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ),
          )
        else
          ..._deliveries.map((d) {
            final batchNum = d.batchNumber ?? 1;
            final totalB = d.totalBatches != null ? '/${d.totalBatches}' : '';

            return Container(
              margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F0FF),
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          border: Border.all(color: const Color(0xFFD3ADF7)),
                        ),
                        child: Text(
                          'Đợt $batchNum$totalB',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF722ED1),
                          ),
                        ),
                      ),
                      Text(
                        d.deliveryNumber,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  if (d.items.isNotEmpty) ...[
                    const Text('Sản phẩm trong đợt:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    ...d.items.map((it) => Text(
                          '• ${it.productName}: ${it.quantity} ${it.unit ?? ""}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                        )),
                    const SizedBox(height: AppTokens.spaceSM),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        d.actualDeliveryDate != null
                            ? 'Đã giao: ${DateFormat("dd/MM/yyyy").format(d.actualDeliveryDate!)}'
                            : (d.estimatedDeliveryDate != null
                                ? 'Hẹn giao: ${DateFormat("dd/MM/yyyy").format(d.estimatedDeliveryDate!)}'
                                : 'Đang sắp xếp lịch'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  // Driver block (D33)
                  DeliveryDriverInfoCard(
                    driverName: d.driverName,
                    driverPhone: d.driverPhone,
                    vehiclePlate: d.vehiclePlate,
                    driverClaimedAt: d.driverClaimedAt,
                    deliveryNumber: d.deliveryNumber,
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  // Button to view PoD
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                    onPressed: () => _showPoDProofsModal(d),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Xem ảnh chứng từ PoD của đợt này', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _statItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
