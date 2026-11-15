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

class RfqListScreen extends ConsumerStatefulWidget {
  const RfqListScreen({super.key});

  @override
  ConsumerState<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends ConsumerState<RfqListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Rfq> _rfqs = [];

  @override
  void initState() {
    super.initState();
    _loadRfqs();
  }

  Future<void> _loadRfqs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(rfqRepositoryProvider);
      final list = await repository.getMyRfqs();
      if (mounted) {
        setState(() {
          _rfqs = list;
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

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'Draft':
        label = 'Bản nháp';
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
        borderColor = AppColors.border;
        break;
      case 'Open':
      case 'OpenForBidding':
        label = 'Đang nhận báo giá';
        bgColor = AppColors.accentGoldBg;
        textColor = AppColors.accent;
        borderColor = AppColors.accent;
        break;
      case 'UnderReview':
        label = 'Đang xét thầu';
        bgColor = AppColors.infoBg;
        textColor = AppColors.info;
        borderColor = AppColors.info;
        break;
      case 'Awarded':
        label = 'Đã chọn xưởng';
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        borderColor = AppColors.success;
        break;
      case 'Completed':
        label = 'Hoàn tất';
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        borderColor = AppColors.success;
        break;
      case 'Cancelled':
        label = 'Đã hủy';
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        borderColor = AppColors.error;
        break;
      default:
        label = status;
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
        borderColor = AppColors.border;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 54, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải danh sách RFQ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CustomButton(
                title: 'Thử lại',
                size: ButtonSize.medium,
                variant: ButtonVariant.primary,
                onPress: _loadRfqs,
              ),
            ],
          ),
        ),
      );
    }

    if (_rfqs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 14),
              const Text(
                'Chưa có yêu cầu báo giá nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo yêu cầu báo giá (RFQ) để nhận báo giá sỉ cạnh tranh và ưu đãi thiết kế hộp từ các xưởng sản xuất uy tín.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              CustomButton(
                title: 'Tạo RFQ ngay',
                size: ButtonSize.medium,
                onPress: () => context.push('/create-rfq').then((res) {
                  if (res == true) _loadRfqs();
                }),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRfqs,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rfqs.length,
        itemBuilder: (context, index) {
          final rfq = _rfqs[index];
          final bidsCount = rfq.bids.isNotEmpty ? rfq.bids.length : rfq.bidCount;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: InkWell(
              onTap: () => context.push('/rfq-detail-bidding', extra: rfq).then((_) => _loadRfqs()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rfq.rfqNumber.isNotEmpty ? rfq.rfqNumber : 'RFQ-${rfq.id.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGoldBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.accent, width: 0.8),
                            ),
                            child: Text(
                              '$bidsCount xưởng nộp bid',
                              style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildStatusBadge(rfq.status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rfq.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Số lượng: ${rfq.targetQuantity} hộp · Dự toán: ${_formatCurrency(rfq.targetBudget ?? rfq.budgetRangeMax ?? 0)}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hạn giao: ${DateFormat('dd/MM/yyyy').format(rfq.expectedDeliveryDate)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const Row(
                        children: [
                          Text('Xem so sánh báo giá', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Yêu Cầu Báo Giá B2B',
        showBack: true,
        rightIcon: Icons.add,
        rightLabel: 'Tạo RFQ',
        onRightPress: () => context.push('/create-rfq').then((res) {
          if (res == true) _loadRfqs();
        }),
      ),
      body: _buildContent(),
    );
  }
}
