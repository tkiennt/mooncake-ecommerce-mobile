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
          _errorMessage = e.toString();
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

  Widget _buildStatusBadge(ContractModel contract) {
    final isPending = _isAwaitingSignature(contract);
    String label;
    Color bgColor;
    Color textColor;

    if (isPending) {
      label = 'Chờ ký số';
      bgColor = AppColors.warningBg;
      textColor = AppColors.warning;
    } else {
      switch (contract.status.toLowerCase()) {
        case 'active':
        case 'signed':
        case 'inproduction':
          label = 'Đang thực hiện';
          bgColor = AppColors.successBg;
          textColor = AppColors.success;
          break;
        case 'completed':
          label = 'Đã hoàn thành';
          bgColor = AppColors.infoBg;
          textColor = AppColors.info;
          break;
        case 'disputed':
          label = 'Đang khiếu nại';
          bgColor = AppColors.errorBg;
          textColor = AppColors.error;
          break;
        case 'cancelled':
          label = 'Đã hủy';
          bgColor = AppColors.errorBg;
          textColor = AppColors.error;
          break;
        default:
          label = contract.status;
          bgColor = AppColors.background;
          textColor = AppColors.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
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
                'Không thể tải danh sách hợp đồng',
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
                onPress: _loadContracts,
              ),
            ],
          ),
        ),
      );
    }

    if (_contracts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 14),
              const Text(
                'Chưa có hợp đồng B2B nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi bạn chấp thuận một báo giá từ xưởng sản xuất, hợp đồng kinh tế điện tử sẽ được lập và hiển thị tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              CustomButton(
                title: 'Xem danh sách RFQ',
                size: ButtonSize.medium,
                onPress: () => context.push('/rfq-list'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContracts,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contracts.length,
        itemBuilder: (context, index) {
          final c = _contracts[index];
          final isPending = _isAwaitingSignature(c);
          final depositText = c.depositAmount > 0
              ? '${_formatCurrency(c.depositAmount)} (${c.depositPercent > 0 ? "${c.depositPercent.toInt()}%" : "Ký quỹ"})'
              : (isPending ? 'Ký quỹ theo điều khoản' : 'Đã thanh toán ký quỹ');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                    Text(
                      c.contractNumber.isNotEmpty ? c.contractNumber : 'HĐ-${c.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    _buildStatusBadge(c),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đối tác sản xuất: ${c.supplierName}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giá trị: ${_formatCurrency(c.totalValue)} · Đặt cọc: $depositText',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                if (isPending)
                  CustomButton(
                    title: 'Ký số hợp đồng ngay',
                    size: ButtonSize.medium,
                    width: double.infinity,
                    onPress: () {
                      context.push(
                        '/contract-sign',
                        extra: {
                          'contractId': c.id,
                          'contractNumber': c.contractNumber,
                          'contract': c,
                        },
                      ).then((_) => _loadContracts());
                    },
                  )
                else
                  CustomButton(
                    title: 'Xem biên bản bàn giao & Xe lạnh',
                    variant: ButtonVariant.outline,
                    size: ButtonSize.medium,
                    width: double.infinity,
                    onPress: () => context.push('/delivery-pod'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Hợp Đồng B2B', showBack: true),
      body: _buildContent(),
    );
  }
}
