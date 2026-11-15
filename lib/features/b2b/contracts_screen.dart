import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/contract.dart';
import '../../data/repositories/contract_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/app_status_chip.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/milestone_timeline.dart';
import 'widgets/contract_fulfillment_table.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ContractModel> _contracts = [];

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(contractRepositoryProvider);
      final list = await repository.getMyContracts();
      if (mounted) {
        setState(() {
          _contracts = list;
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

  bool _isAwaitingSignature(ContractModel contract) {
    if (contract.needsCustomerSignature) return true;
    final status = contract.status.toLowerCase();
    return status == 'draft' ||
        status == 'pendingsignature' ||
        status == 'awaitingsignature' ||
        contract.signedByCustomerAt == null;
  }

  List<MilestoneItem> _buildContractMilestones(ContractModel contract) {
    final status = contract.status.toLowerCase();
    final isSigned = contract.signedByCustomerAt != null ||
        status == 'signed' ||
        status == 'active' ||
        status == 'inproduction' ||
        status == 'completed';

    final isPaidDeposit = contract.depositAmount > 0 &&
        (status == 'active' || status == 'inproduction' || status == 'completed');

    final isInProduction = status == 'inproduction' || status == 'completed';
    final isCompleted = status == 'completed';

    // If backend provided milestones, adapt them
    if (contract.milestones.isNotEmpty) {
      return contract.milestones.map((m) {
        final mStatus = m.status.toLowerCase();
        MilestoneStepStatus stepStatus = MilestoneStepStatus.upcoming;
        if (m.isCompleted) {
          stepStatus = MilestoneStepStatus.completed;
        } else if (m.isOverdue) {
          stepStatus = MilestoneStepStatus.failed;
        } else if (mStatus == 'current' || mStatus == 'in_progress' || mStatus == 'pending') {
          stepStatus = MilestoneStepStatus.current;
        }

        String titleText = m.name;
        if (m.isOverdue) {
          titleText = '${m.name} [Quá hạn]';
        } else if (m.isNearDeadline) {
          titleText = '${m.name} [${m.dueNoticeTag}]';
        }

        return MilestoneItem(
          title: titleText,
          subtitle: m.amount > 0 ? _formatCurrency(m.amount) : null,
          timestamp: m.dueDate.isNotEmpty ? m.dueDate : null,
          status: stepStatus,
        );
      }).toList();
    }

    // Standard 4 contract milestones
    return [
      MilestoneItem(
        title: 'Ký kết HĐ',
        subtitle: isSigned ? 'Đã ký số' : 'Chờ khách ký',
        status: isSigned ? MilestoneStepStatus.completed : MilestoneStepStatus.current,
        timestamp: contract.signedByCustomerAt != null
            ? DateFormat('dd/MM').format(contract.signedByCustomerAt!)
            : null,
      ),
      MilestoneItem(
        title: 'Đặt cọc 30%',
        subtitle: isPaidDeposit ? 'Đã ký quỹ' : 'Chờ nộp cọc',
        status: isPaidDeposit
            ? MilestoneStepStatus.completed
            : (isSigned ? MilestoneStepStatus.current : MilestoneStepStatus.upcoming),
      ),
      MilestoneItem(
        title: 'Sản xuất',
        subtitle: isInProduction ? 'Đang ra lò' : 'Chuẩn bị vật tư',
        status: isInProduction
            ? (isCompleted ? MilestoneStepStatus.completed : MilestoneStepStatus.current)
            : MilestoneStepStatus.upcoming,
      ),
      MilestoneItem(
        title: 'Giao PoD',
        subtitle: isCompleted ? 'Đã nhận đủ' : 'Xe lạnh vận chuyển',
        status: isCompleted ? MilestoneStepStatus.completed : MilestoneStepStatus.upcoming,
      ),
    ];
  }

  void _showContractDetailsModal(ContractModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
          ),
          child: Column(
            children: [
              // Handle
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.contractNumber.isNotEmpty ? c.contractNumber : 'Hợp Đồng Kinh Tế Điện Tử',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Văn bản hợp đồng kinh tế theo Luật Giao dịch điện tử',
                            style: TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: AppColors.textSecondary),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parties Header Box
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BÊN A (BÊN ĐẶT HÀNG / KHÁCH HÀNG DOANH NGHIỆP):',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                            ),
                            Text(
                              c.customerName ?? 'Quý Doanh Nghiệp đặt hàng qua Nguyệt Phố B2B',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'BÊN B (BÊN SẢN XUẤT / NHÀ CUNG CẤP):',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary),
                            ),
                            Text(
                              c.supplierName,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceLG),

                      // Contract Articles
                      const Text(
                        'ĐIỀU 1. ĐỐI TƯỢNG HỢP ĐỒNG & QUY CÁCH',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bên B cam kết cung ứng các sản phẩm bánh trung thu thủ công cao cấp theo đúng tiêu chuẩn chất lượng, bao bì in laser logo thương hiệu bên A đã phê duyệt trong hồ sơ đấu giá.',
                        style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),

                      const Text(
                        'ĐIỀU 2. GIÁ TRỊ HỢP ĐỒNG & TIẾN ĐỘ THANH TOÁN',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Tổng giá trị hợp đồng trọn gói: ${_formatCurrency(c.totalValue)} (Đã bao gồm thuế GTGT và phí vận chuyển xe lạnh).\n'
                        '• Đợt 1 (Ký quỹ đặt cọc): 30% giá trị hợp đồng (${_formatCurrency(c.totalValue * 0.3)}) sau khi ký số hợp đồng.\n'
                        '• Đợt 2 (Thanh toán hoàn tất): 70% giá trị còn lại sau khi Bên A kiểm tra biên bản giao nhận PoD và xác nhận đủ số lượng, nguyên vẹn.',
                        style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),

                      const Text(
                        'ĐIỀU 3. TIÊU CHUẨN BẢO QUẢN & VẬN CHUYỂN XE LẠNH',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Toàn bộ kiện hàng được vận chuyển bằng xe lạnh chuyên dụng kiểm soát nhiệt độ từ 18-25°C. Bên B có trách nhiệm cung cấp dữ liệu cảm biến xe lạnh và chứng từ PoD kèm ảnh chụp tem seal.',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),

                      const Text(
                        'ĐIỀU 4. CHỮ KÝ SỐ VÀ HIỆU LỰC HỢP ĐỒNG',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hợp đồng được ký số qua mã OTP xác thực email và chữ ký điện tử. Các bên cam kết thực hiện đúng mọi điều khoản theo quy định pháp luật Việt Nam.',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: AppTokens.space2XL),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                child: CustomButton(
                  title: _isAwaitingSignature(c) ? 'Tiến hành ký số hợp đồng ngay' : 'Đóng văn bản',
                  size: ButtonSize.large,
                  width: double.infinity,
                  onPress: () {
                    Navigator.of(ctx).pop();
                    if (_isAwaitingSignature(c)) {
                      context.push(
                        '/contract-sign',
                        extra: {
                          'contractId': c.id,
                          'contractNumber': c.contractNumber,
                          'contract': c,
                        },
                      ).then((_) => _loadContracts());
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFulfillmentModal(ContractModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đối Soát Giao Hàng · ${c.contractNumber}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(height: 12, color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  child: ContractFulfillmentTable(
                    contractId: c.id,
                    contractNumber: c.contractNumber,
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
    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      itemCount: 3,
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
                      width: 120,
                      height: 18,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                    ),
                  ),
                  AppSkeleton.shimmer(
                    child: Container(
                      width: 80,
                      height: 20,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusPill)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceMD),
              AppSkeleton.shimmer(
                child: Container(
                  width: 240,
                  height: 16,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                ),
              ),
              const SizedBox(height: AppTokens.spaceSM),
              AppSkeleton.shimmer(
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),
              AppSkeleton.shimmer(
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                ),
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
        title: 'Không thể tải danh sách hợp đồng',
        message: _errorMessage!,
        onRetry: _loadContracts,
        retryLabel: 'Thử lại ngay',
      );
    }

    if (_contracts.isEmpty) {
      return AppEmptyState(
        icon: Icons.description_outlined,
        title: 'Chưa có hợp đồng B2B nào',
        message: 'Khi bạn chấp thuận một báo giá từ xưởng sản xuất, hợp đồng kinh tế điện tử sẽ được lập và hiển thị tại đây.',
        actionLabel: 'Xem danh sách RFQ',
        onAction: () => context.push('/rfq-list'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContracts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        itemCount: _contracts.length,
        itemBuilder: (context, index) {
          final c = _contracts[index];
          final isPending = _isAwaitingSignature(c);
          final depositText = c.depositAmount > 0
              ? '${_formatCurrency(c.depositAmount)} (${c.depositPercent > 0 ? "${c.depositPercent.toInt()}%" : "Ký quỹ"})'
              : (isPending ? 'Ký quỹ 30% khi ký số' : 'Đã xác nhận ký quỹ');

          final milestones = _buildContractMilestones(c);

          return Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: isPending ? AppColors.warning : AppColors.border,
                width: isPending ? 1.2 : 0.8,
              ),
              boxShadow: AppTokens.shadowCard,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contract Number & Status Chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          c.contractNumber.isNotEmpty ? c.contractNumber : 'HĐ-${c.id.length > 8 ? c.id.substring(0, 8) : c.id}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSM),
                      AppStatusChip(
                        status: isPending ? 'PendingSignature' : c.status,
                        type: AppStatusType.contract,
                        size: AppStatusChipSize.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),

                  // Title & Supplier
                  Text(
                    c.title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Đối tác: ${c.supplierName}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceMD),

                  // Two-Party Signing Status Box (D22)
                  Container(
                    margin: const EdgeInsets.only(top: AppTokens.spaceSM),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.spaceMD,
                      vertical: AppTokens.spaceSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                c.isCustomerSigned ? Icons.check_circle : Icons.schedule,
                                size: 14,
                                color: c.isCustomerSigned ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Khách: ${c.isCustomerSigned ? "Đã ký số" : "Chờ bạn ký"}',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.isCustomerSigned ? AppColors.success : AppColors.warning,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 16, color: AppColors.border),
                        const SizedBox(width: AppTokens.spaceSM),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                c.isSupplierSigned ? Icons.check_circle : Icons.schedule,
                                size: 14,
                                color: c.isSupplierSigned ? AppColors.success : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Xưởng: ${c.isSupplierSigned ? "Đã ký số" : "Chờ xưởng ký"}',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.isSupplierSigned ? AppColors.success : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Value & Deposit Card
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
                            const Text('Giá trị hợp đồng', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(c.totalValue),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Khoản đặt cọc', style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              depositText,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12.5,
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

                  // Milestone Alerts (Overdue / Near Deadline)
                  if (c.milestones.any((m) => m.isOverdue || m.isNearDeadline)) ...[
                    const SizedBox(height: AppTokens.spaceSM),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: c.milestones
                          .where((m) => m.isOverdue || m.isNearDeadline)
                          .map(
                            (m) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: m.isOverdue ? AppColors.errorBg : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: m.isOverdue ? AppColors.error : AppColors.warning,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m.isOverdue ? Icons.error_outline : Icons.access_time,
                                    size: 13,
                                    color: m.isOverdue ? AppColors.error : AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Mốc "${m.name}": ${m.dueNoticeTag}',
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: m.isOverdue ? AppColors.error : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // MilestoneTimeline
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSM),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                    ),
                    child: MilestoneTimeline(
                      items: milestones,
                      orientation: Axis.horizontal,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppTokens.spaceMD),

                  // Action Buttons: "Xem văn bản đầy đủ" + "Ký số / Theo dõi PoD"
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                            minimumSize: const Size(0, AppTokens.minTapTarget),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _showContractDetailsModal(c),
                          child: const Text(
                            'Xem văn bản đầy đủ',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceMD),
                      Expanded(
                        child: isPending
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textWhite,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                                  minimumSize: const Size(0, AppTokens.minTapTarget),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () {
                                  context.push(
                                    '/contract-sign',
                                    extra: {
                                      'contractId': c.id,
                                      'contractNumber': c.contractNumber,
                                      'contract': c,
                                    },
                                  ).then((_) => _loadContracts());
                                },
                                child: const Text(
                                  'Ký số hợp đồng',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentGoldBg,
                                  foregroundColor: AppColors.accent,
                                  side: const BorderSide(color: AppColors.accent, width: 0.8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                                  minimumSize: const Size(0, AppTokens.minTapTarget),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () => _showFulfillmentModal(c),
                                label: const Text(
                                  'Đợt giao & PoD',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Hợp Đồng B2B', showBack: true),
      body: _buildContent(),
    );
  }
}
