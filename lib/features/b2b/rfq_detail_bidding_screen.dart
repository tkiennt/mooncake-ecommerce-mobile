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

class RfqDetailBiddingScreen extends ConsumerStatefulWidget {
  final Rfq rfq;

  const RfqDetailBiddingScreen({super.key, required this.rfq});

  @override
  ConsumerState<RfqDetailBiddingScreen> createState() => _RfqDetailBiddingScreenState();
}

class _RfqDetailBiddingScreenState extends ConsumerState<RfqDetailBiddingScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RfqBid> _bids = [];
  String? _acceptingBidId;

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
      final fetchedBids = await repository.getRfqBids(widget.rfq.id);
      if (mounted) {
        setState(() {
          _bids = fetchedBids.isNotEmpty ? fetchedBids : widget.rfq.bids;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback to rfq.bids if available, otherwise show error
        if (widget.rfq.bids.isNotEmpty) {
          setState(() {
            _bids = widget.rfq.bids;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  Future<void> _handleAcceptBid(RfqBid bid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận chọn xưởng', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Quý khách có chắc chắn muốn chấp thuận báo giá từ "${bid.supplierName}" với giá trị ${_formatCurrency(bid.quotedPrice)} để tiến hành lập hợp đồng kinh tế?',
          style: const TextStyle(height: 1.4),
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
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý & Lập HĐ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _acceptingBidId = bid.id);

    try {
      final repository = ref.read(rfqRepositoryProvider);
      final result = await repository.acceptBid(widget.rfq.id, bid.id);

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
        // Fallback: điều hướng sang ký hợp đồng với dữ liệu báo giá đã chọn
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
            content: Text('Lỗi chấp thuận báo giá: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingBidId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rfq = widget.rfq;

    return Scaffold(
      appBar: AppHeader(
        title: 'Đấu Thầu ${rfq.rfqNumber}',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBids,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RFQ Overview Card
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
                    Text(rfq.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(
                      'Số lượng: ${rfq.targetQuantity} hộp · Dự toán: ${_formatCurrency(rfq.targetBudget ?? rfq.budgetRangeMax ?? 0)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hạn giao: ${DateFormat('dd/MM/yyyy').format(rfq.expectedDeliveryDate)}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    if (rfq.deliveryAddress != null && rfq.deliveryAddress!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Địa chỉ: ${rfq.deliveryAddress}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                    if (rfq.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Ghi chú: ${rfq.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bids Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Danh Sách Báo Giá Từ Các Xưởng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (!_isLoading && _bids.isNotEmpty)
                    Text(
                      '${_bids.length} báo giá',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Loading / Error / Empty / Bids List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        title: 'Tải lại báo giá',
                        size: ButtonSize.small,
                        onPress: _loadBids,
                      ),
                    ],
                  ),
                )
              else if (_bids.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có xưởng nào nộp báo giá',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Các xưởng sản xuất đã nhận được yêu cầu và đang lập bảng dự toán chi phí. Báo giá sẽ xuất hiện tại đây khi xưởng gửi nộp.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                )
              else
                ..._bids.map((bid) {
                  final unitPrice = rfq.targetQuantity > 0
                      ? (bid.quotedPrice / rfq.targetQuantity).roundToDouble()
                      : bid.quotedPrice;
                  final isAcceptingThis = _acceptingBidId == bid.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                      border: Border.all(color: AppColors.border, width: 0.8),
                      boxShadow: AppTokens.shadowCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                bid.supplierName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Xưởng kiểm định',
                                style: TextStyle(color: AppColors.success, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatCurrency(bid.quotedPrice),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            Text('(${_formatCurrency(unitPrice)}/hộp)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ngày cam kết giao: ${bid.deliveryDate.isNotEmpty ? bid.deliveryDate : (bid.estimatedDeliveryDays != null ? "${bid.estimatedDeliveryDays} ngày" : "Theo thỏa thuận")}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        if (bid.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Ưu đãi: ${bid.note}', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 14),

                        // Accept Bid CTA
                        CustomButton(
                          title: 'Chấp thuận báo giá & Tiến hành ký HĐ',
                          size: ButtonSize.medium,
                          width: double.infinity,
                          loading: isAcceptingThis,
                          disabled: _acceptingBidId != null,
                          onPress: () => _handleAcceptBid(bid),
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
