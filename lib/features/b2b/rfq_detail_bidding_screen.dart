import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/rfq.dart';
import '../../data/repositories/rfq_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';

class RfqDetailBiddingScreen extends ConsumerStatefulWidget {
  final Rfq rfq;
  final String? rfqId;

  const RfqDetailBiddingScreen({
    super.key,
    required this.rfq,
    this.rfqId,
  });

  @override
  ConsumerState<RfqDetailBiddingScreen> createState() => _RfqDetailBiddingScreenState();
}

class _RfqDetailBiddingScreenState extends ConsumerState<RfqDetailBiddingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RfqBid> _bids = [];
  String? _acceptingBidId;
  String _selectedSort = 'price_asc'; // price_asc, delivery_asc, all

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(rfqRepositoryProvider);
      final rfqId = widget.rfq.id.isNotEmpty ? widget.rfq.id : (widget.rfqId ?? '');
      final fetchedBids = await repository.getRfqBids(rfqId);
      if (mounted) {
        setState(() {
          _bids = fetchedBids.isNotEmpty ? fetchedBids : widget.rfq.bids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (widget.rfq.bids.isNotEmpty) {
          setState(() {
            _bids = widget.rfq.bids;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  List<RfqBid> get _sortedBids {
    final list = List<RfqBid>.from(_bids);
    if (_selectedSort == 'price_asc') {
      list.sort((a, b) => a.quotedPrice.compareTo(b.quotedPrice));
    } else if (_selectedSort == 'delivery_asc') {
      list.sort((a, b) {
        final daysA = a.estimatedDeliveryDays ?? 999;
        final daysB = b.estimatedDeliveryDays ?? 999;
        return daysA.compareTo(daysB);
      });
    }
    return list;
  }

  RfqBid? get _lowestPriceBid {
    if (_bids.isEmpty) return null;
    RfqBid lowest = _bids.first;
    for (final b in _bids) {
      if (b.quotedPrice < lowest.quotedPrice) {
        lowest = b;
      }
    }
    return lowest;
  }

  RfqBid? get _fastestDeliveryBid {
    if (_bids.isEmpty) return null;
    RfqBid fastest = _bids.first;
    for (final b in _bids) {
      final daysB = b.estimatedDeliveryDays ?? 999;
      final daysFastest = fastest.estimatedDeliveryDays ?? 999;
      if (daysB < daysFastest) {
        fastest = b;
      }
    }
    return fastest;
  }

  Future<void> _handleAcceptBid(RfqBid bid) async {
    // D28: Warning modal when awarding RFQ with < 2 bids
    if (_bids.length < 2) {
      final proceedFewBids = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Text(
                'Cảnh báo ít báo giá',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yêu cầu báo giá (RFQ) này hiện chỉ có ${_bids.length} báo giá từ xưởng.',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Để đảm bảo tính cạnh tranh về giá và chất lượng, hệ thống khuyến nghị nên có từ 2 báo giá trở lên trước khi trao thầu.\n\nBạn có chắc chắn muốn tiếp tục trao thầu cho xưởng này ngay bây giờ?',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Xem lại / Chờ thêm', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.textWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Vẫn trao thầu', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (proceedFewBids != true) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        title: const Row(
          children: [
            Icon(Icons.handshake_outlined, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Xác nhận chọn xưởng',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quý khách có chắc chắn muốn chấp thuận báo giá từ xưởng:',
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bid.supplierName,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng giá trị: ${_formatCurrency(bid.quotedPrice)}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hệ thống sẽ tiến hành khởi tạo hợp đồng kinh tế và chuyển sang bước ký số bằng chữ ký tay & OTP Email.',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(120, AppTokens.minTapTarget),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý & Ký HĐ', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _acceptingBidId = bid.id);

    try {
      final repository = ref.read(rfqRepositoryProvider);
      final rfqId = widget.rfq.id.isNotEmpty ? widget.rfq.id : (widget.rfqId ?? '');
      final result = await repository.acceptBid(rfqId, bid.id);

      if (!mounted) return;

      final contractData = result['contract'] as Map<String, dynamic>?;
      final awaitingSupplier = result['awaitingSupplierConfirmation'] == true;

      if (contractData != null && contractData.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Chấp thuận báo giá thành công! Đang chuyển sang màn hình ký số hợp đồng...'),
          ),
        );

        final contractId = contractData['id']?.toString() ?? '';
        final contractNumber = contractData['contractNumber']?.toString() ??
            'HD-${widget.rfq.rfqNumber.replaceAll("RFQ-", "")}';

        context.push(
          '/contract-sign',
          extra: {
            'contractId': contractId,
            'contractNumber': contractNumber,
            'contract': contractData,
            'bid': bid,
            'rfq': widget.rfq,
          },
        );
      } else if (awaitingSupplier) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Đã gửi xác nhận tới xưởng'),
            content: Text(
              result['message']?.toString() ??
                  'Hệ thống đã ghi nhận lựa chọn xưởng của bạn. Xưởng sản xuất sẽ xác nhận và khởi tạo hợp đồng điện tử trong thời gian sớm nhất.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        context.push(
          '/contract-sign',
          extra: {
            'contractNumber': 'HD-${widget.rfq.rfqNumber}-KD',
            'bid': bid,
            'rfq': widget.rfq,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi chấp thuận báo giá: ${e.toString().replaceFirst('Exception: ', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingBidId = null);
      }
    }
  }

  void _showComparisonMatrixModal() {
    final bids = _bids;
    if (bids.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
          ),
          child: Column(
            children: [
              // Handle & Header
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceSM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảng So Sánh Báo Giá Các Xưởng',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Đối chiếu giá, thời gian và năng lực sản xuất',
                          style: TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTokens.spaceLG),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.background),
                      headingTextStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 12.5,
                      ),
                      columns: [
                        const DataColumn(label: Text('Tiêu chí đối chiếu')),
                        ...bids.map((b) => DataColumn(
                              label: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  b.supplierName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('Tổng báo giá', style: TextStyle(fontWeight: FontWeight.w600))),
                          ...bids.map((b) => DataCell(Text(
                                _formatCurrency(b.quotedPrice),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ))),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Đơn giá / hộp')),
                          ...bids.map((b) {
                            final unit = widget.rfq.targetQuantity > 0
                                ? (b.quotedPrice / widget.rfq.targetQuantity).roundToDouble()
                                : b.quotedPrice;
                            return DataCell(Text('${_formatCurrency(unit)}/hộp'));
                          }),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Thời gian giao')),
                          ...bids.map((b) => DataCell(Text(
                                b.deliveryDate.isNotEmpty
                                    ? b.deliveryDate
                                    : (b.estimatedDeliveryDays != null ? '${b.estimatedDeliveryDays} ngày' : 'Theo HĐ'),
                              ))),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Xe lạnh bảo quản')),
                          ...bids.map((_) => const DataCell(Row(
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('20-25°C'),
                                ],
                              ))),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Mẫu hộp kiểm thử')),
                          ...bids.map((_) => const DataCell(Row(
                                children: [
                                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                                  SizedBox(width: 4),
                                  Text('Có mẫu seal'),
                                ],
                              ))),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('Hành động')),
                          ...bids.map((b) => DataCell(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textWhite,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(60, 32),
                                  ),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _handleAcceptBid(b);
                                  },
                                  child: const Text('Chọn xưởng', style: TextStyle(fontSize: 11.5)),
                                ),
                              )),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 140,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                  ),
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMD),
              AppSkeleton.shimmer(
                child: Container(
                  width: 180,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceSM),
              AppSkeleton.shimmer(
                child: Container(
                  width: 220,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),
              AppSkeleton.shimmer(
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rfq = widget.rfq;
    final bids = _sortedBids;
    final lowestBid = _lowestPriceBid;
    final fastestBid = _fastestDeliveryBid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Đấu Thầu ${rfq.rfqNumber.isNotEmpty ? rfq.rfqNumber : "RFQ"}',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBids,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. RFQ Overview Card
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            rfq.title,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spaceSM),
                        AppStatusChip(
                          status: rfq.status,
                          type: AppStatusType.rfq,
                          size: AppStatusChipSize.small,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceMD),
                    Wrap(
                      spacing: AppTokens.spaceLG,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Số lượng: ${rfq.targetQuantity} hộp',
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Dự toán: ${_formatCurrency(rfq.targetBudget ?? rfq.budgetRangeMax ?? 0)}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event_available_outlined, size: 15, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Hạn cần giao: ${DateFormat('dd/MM/yyyy').format(rfq.expectedDeliveryDate)}',
                          style: const TextStyle(fontFamily: 'Roboto', fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    if (rfq.deliveryAddress != null && rfq.deliveryAddress!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Địa chỉ: ${rfq.deliveryAddress}',
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),

              // 2. Summary Metric Bar (Thống kê so sánh nhanh)
              if (!_isLoading && _bids.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD, vertical: AppTokens.spaceMD),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldBg,
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Tổng số báo giá', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text('${_bids.length} xưởng', style: const TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.accent.withValues(alpha: 0.3)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Giá tốt nhất', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              lowestBid != null ? _formatCurrency(lowestBid.quotedPrice) : '-',
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: AppColors.accent.withValues(alpha: 0.3)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Giao nhanh nhất', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              fastestBid != null ? (fastestBid.estimatedDeliveryDays != null ? '${fastestBid.estimatedDeliveryDays} ngày' : fastestBid.deliveryDate) : '-',
                              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLG),
              ],

              // 3. Section Header & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'So Sánh Báo Giá Xưởng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (!_isLoading && _bids.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(60, AppTokens.minTapTarget),
                      ),
                      icon: const Icon(Icons.table_chart_outlined, size: 16, color: AppColors.primary),
                      label: const Text('Bảng chi tiết', style: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      onPressed: _showComparisonMatrixModal,
                    ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceSM),

              // Filter Chips
              if (!_isLoading && _bids.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Giá thấp nhất', style: TextStyle(fontSize: 12)),
                        selected: _selectedSort == 'price_asc',
                        selectedColor: AppColors.primaryTint,
                        onSelected: (val) {
                          if (val) setState(() => _selectedSort = 'price_asc');
                        },
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      ChoiceChip(
                        label: const Text('Giao nhanh nhất', style: TextStyle(fontSize: 12)),
                        selected: _selectedSort == 'delivery_asc',
                        selectedColor: AppColors.primaryTint,
                        onSelected: (val) {
                          if (val) setState(() => _selectedSort = 'delivery_asc');
                        },
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      ChoiceChip(
                        label: const Text('Tất cả', style: TextStyle(fontSize: 12)),
                        selected: _selectedSort == 'all',
                        selectedColor: AppColors.primaryTint,
                        onSelected: (val) {
                          if (val) setState(() => _selectedSort = 'all');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
              ],

              // 4. Content Area
              if (_isLoading)
                _buildLoadingSkeleton()
              else if (_errorMessage != null)
                AppErrorState(
                  title: 'Không thể tải báo giá',
                  message: _errorMessage!,
                  onRetry: _loadBids,
                  retryLabel: 'Tải lại báo giá',
                )
              else if (_bids.isEmpty)
                const AppEmptyState(
                  icon: Icons.hourglass_empty_rounded,
                  title: 'Chưa có xưởng nào nộp báo giá',
                  message: 'Các xưởng sản xuất đã nhận được yêu cầu và đang lập bảng dự toán chi phí. Báo giá cạnh tranh sẽ xuất hiện tại đây khi xưởng gửi nộp.',
                )
              else
                ...bids.map((bid) {
                  final unitPrice = rfq.targetQuantity > 0
                      ? (bid.quotedPrice / rfq.targetQuantity).roundToDouble()
                      : bid.quotedPrice;
                  final isAcceptingThis = _acceptingBidId == bid.id;
                  final isLowestPrice = lowestBid?.id == bid.id;
                  final isFastest = fastestBid?.id == bid.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(
                        color: isLowestPrice ? AppColors.accent : AppColors.border,
                        width: isLowestPrice ? 1.4 : 0.8,
                      ),
                      boxShadow: AppTokens.shadowCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Highlight Ribbon
                        if (isLowestPrice || isFastest)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowestPrice ? AppColors.accentGoldBg : AppColors.successBg,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard - 1)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isLowestPrice ? Icons.stars : Icons.bolt,
                                  size: 14,
                                  color: isLowestPrice ? AppColors.accent : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isLowestPrice ? 'BÁO GIÁ TIẾT KIỆM NHẤT' : 'TIẾN ĐỘ GIAO NHANH NHẤT',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isLowestPrice ? AppColors.accent : AppColors.success,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(AppTokens.spaceLG),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Workshop Name & Verified Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bid.supplierName,
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Row(
                                          children: [
                                            Icon(Icons.verified, size: 13, color: AppColors.success),
                                            SizedBox(width: 3),
                                            Text(
                                              'Xưởng đạt chuẩn ISO / HACCP',
                                              style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppTokens.spaceSM),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceHover,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Text(
                                      'Bảo quản xe lạnh',
                                      style: TextStyle(fontSize: 10.5, color: AppColors.info, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.spaceMD),

                              // Price Matrix
                              Container(
                                padding: const EdgeInsets.all(AppTokens.spaceMD),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tổng trọn gói', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatCurrency(bid.quotedPrice),
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Đơn giá dự kiến', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatCurrency(unitPrice)}/hộp',
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTokens.spaceMD),

                              // Key details: Delivery & Note
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 15, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Cam kết giao: ${bid.deliveryDate.isNotEmpty ? bid.deliveryDate : (bid.estimatedDeliveryDays != null ? "${bid.estimatedDeliveryDays} ngày sản xuất" : "Theo thỏa thuận")}',
                                      style: const TextStyle(fontFamily: 'Roboto', fontSize: 12.5, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              if (bid.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.card_giftcard, size: 15, color: AppColors.accent),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ưu đãi: ${bid.note}',
                                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: AppTokens.spaceLG),

                              // CTA: Accept Bid & Proceed to Contract
                              CustomButton(
                                title: 'Chấp thuận báo giá & Lập hợp đồng',
                                size: ButtonSize.medium,
                                width: double.infinity,
                                loading: isAcceptingThis,
                                disabled: _acceptingBidId != null,
                                onPress: () => _handleAcceptBid(bid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
