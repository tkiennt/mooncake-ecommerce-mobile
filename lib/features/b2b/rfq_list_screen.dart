import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/rfq.dart';
import '../../data/repositories/rfq_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';

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
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
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
                      width: 110,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                  ),
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 90,
                      height: 22,
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
                  width: double.infinity,
                  height: 16,
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
              const SizedBox(height: AppTokens.spaceMD),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                  ),
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Không thể tải danh sách RFQ',
        message: _errorMessage!,
        onRetry: _loadRfqs,
        retryLabel: 'Thử lại ngay',
      );
    }

    if (_rfqs.isEmpty) {
      return AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Chưa có yêu cầu báo giá nào',
        message: 'Tạo yêu cầu báo giá (RFQ) để nhận báo giá sỉ cạnh tranh và ưu đãi thiết kế hộp từ các xưởng sản xuất uy tín.',
        actionLabel: 'Tạo RFQ ngay',
        onAction: () => context.push('/create-rfq').then((res) {
          if (res == true) _loadRfqs();
        }),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRfqs,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: _rfqs.length,
        itemBuilder: (context, index) {
          final rfq = _rfqs[index];
          final bidsCount = rfq.bids.isNotEmpty ? rfq.bids.length : rfq.bidCount;

          return Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: AppTokens.shadowSubtle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                onTap: () => context.push('/rfq-detail-bidding', extra: rfq).then((_) => _loadRfqs()),
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: RFQ number + Wrap status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rfq.rfqNumber.isNotEmpty ? rfq.rfqNumber : 'RFQ-${rfq.id.length > 8 ? rfq.id.substring(0, 8) : rfq.id}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSM),
                          Flexible(
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (bidsCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGoldBg,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                      border: Border.all(color: AppColors.accent, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.gavel, size: 12, color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$bidsCount báo giá',
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            color: AppColors.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                AppStatusChip(
                                  status: rfq.status,
                                  type: AppStatusType.rfq,
                                  size: AppStatusChipSize.small,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      // Title
                      Text(
                        rfq.title,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTokens.spaceSM),
                      // Quantity & Budget
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Số lượng: ${rfq.targetQuantity} hộp',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceMD),
                          const Icon(Icons.payments_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Dự toán: ${_formatCurrency(rfq.targetBudget ?? rfq.budgetRangeMax ?? 0)}',
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: AppTokens.spaceMD),
                      // Footer: Delivery Date & CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Hạn giao: ${DateFormat('dd/MM/yyyy').format(rfq.expectedDeliveryDate)}',
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSM),
                          Container(
                            constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'So sánh báo giá',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Yêu Cầu Báo Giá B2B',
        showBack: true,
        rightIcon: Icons.add_circle_outline,
        rightLabel: 'Tạo RFQ',
        onRightPress: () => context.push('/create-rfq').then((res) {
          if (res == true) _loadRfqs();
        }),
      ),
      body: _buildContent(),
    );
  }
}
