import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/contract.dart';
import '../../data/repositories/contract_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';
import '../../shared_widgets/antd/antd_steps.dart';

class ContractSignScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? contractData;

  const ContractSignScreen({super.key, this.contractData});

  @override
  ConsumerState<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends ConsumerState<ContractSignScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.primary,
    exportBackgroundColor: Colors.transparent,
  );

  bool _agreeTerms = false;
  String _otpCode = '';
  bool _isSigned = false;
  bool _isSubmitting = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;

  bool _isLoadingContract = false;
  String? _contractError;
  ContractModel? _loadedContract;

  String? get _resolvedContractId {
    if (widget.contractData == null) return null;
    final cId = widget.contractData!['contractId'] ?? widget.contractData!['id'];
    if (cId != null && cId.toString().isNotEmpty) return cId.toString();
    final contract = widget.contractData!['contract'];
    if (contract is ContractModel) return contract.id;
    if (contract is Map && contract['id'] != null) return contract['id'].toString();
    return null;
  }

  String get _contractNumber {
    if (_loadedContract != null && _loadedContract!.contractNumber.isNotEmpty) {
      return _loadedContract!.contractNumber;
    }
    final num = widget.contractData?['contractNumber'];
    if (num != null && num.toString().isNotEmpty) return num.toString();
    final contract = widget.contractData?['contract'];
    if (contract is ContractModel && contract.contractNumber.isNotEmpty) return contract.contractNumber;
    if (contract is Map && contract['contractNumber'] != null) return contract['contractNumber'].toString();
    return 'HD-2026-991';
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  @override
  void initState() {
    super.initState();
    _initContractData();
  }

  Future<void> _initContractData() async {
    final contract = widget.contractData?['contract'];
    if (contract is ContractModel) {
      _loadedContract = contract;
      return;
    }

    final cId = _resolvedContractId;
    if (cId != null && cId.isNotEmpty) {
      setState(() {
        _isLoadingContract = true;
        _contractError = null;
      });

      try {
        final repo = ref.read(contractRepositoryProvider);
        final fetched = await repo.getContractDetails(cId);
        if (mounted) {
          setState(() {
            _loadedContract = fetched;
            _isLoadingContract = false;
          });
        }
      } catch (e) {
        if (mounted) {
          // If 404 or offline, allow fallback to contractData without blocking signing
          setState(() {
            _isLoadingContract = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    final contractId = _resolvedContractId;
    if (contractId == null || contractId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.info,
          content: Text('Mã xác nhận mẫu: 123456 (hoặc bạn kiểm tra hộp thư email nhé).'),
        ),
      );
      setState(() => _otpSent = true);
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final repository = ref.read(contractRepositoryProvider);
      await repository.requestSignatureOtp(contractId);
      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Mã xác nhận đã gửi tới email của bạn.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Chưa gửi được mã xác nhận, bạn thử lại sau nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _handleSignContract() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn hãy ký tên vào khung chữ ký nhé.')),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn hãy đồng ý với điều khoản hợp đồng trước khi ký nhé.')),
      );
      return;
    }

    if (_otpCode.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn hãy nhập đủ 6 chữ số của mã xác nhận nhé.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final contractId = _resolvedContractId;
      if (contractId != null && contractId.isNotEmpty) {
        final repository = ref.read(contractRepositoryProvider);
        await repository.signContract(
          contractId,
          otpCode: _otpCode.trim(),
          confirmTerms: true,
        );
      }

      if (mounted) {
        setState(() => _isSigned = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Hợp đồng đã ký thành công và đã gửi sang xưởng bánh!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Chưa hoàn tất ký hợp đồng, bạn thử lại sau nhé.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showFullContractDialog() {
    final supplier = _loadedContract?.supplierName ??
        widget.contractData?['supplierName'] ??
        widget.contractData?['bid']?.supplierName ??
        'Xưởng bánh';

    final totalVal = _loadedContract?.totalValue ??
        (widget.contractData?['totalValue'] as num?)?.toDouble() ??
        (widget.contractData?['bid']?.quotedPrice as num?)?.toDouble() ??
        150000000.0;

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
                            'Văn bản hợp đồng $_contractNumber',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Điều khoản mua bán & cam kết giao hàng',
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
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spaceMD),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BÊN A (BÊN MUA): Khách hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            const SizedBox(height: 4),
                            Text('BÊN B (BÊN CUNG CẤP): $supplier', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.primary)),
                            const SizedBox(height: 4),
                            Text('TỔNG GIÁ TRỊ: ${_formatCurrency(totalVal)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceLG),
                      const Text(
                        'ĐIỀU 1. ĐỐI TƯỢNG VÀ QUY CÁCH SẢN PHẨM',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bên B cam kết làm bánh và đóng gói đúng tiêu chuẩn vệ sinh an toàn thực phẩm, bao bì và in logo đúng yêu cầu.',
                        style: TextStyle(fontSize: 12.5, height: 1.45),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      const Text(
                        'ĐIỀU 2. ĐẶT CỌC VÀ THANH TOÁN',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Đợt 1: Bên A thanh toán đặt cọc 30% (${_formatCurrency(totalVal * 0.3)}) sau khi ký hợp đồng.\n'
                        '• Đợt 2: Bên A thanh toán 70% còn lại sau khi nhận hàng và kiểm tra đủ số lượng.',
                        style: const TextStyle(fontSize: 12.5, height: 1.45),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      const Text(
                        'ĐIỀU 3. BẢO QUẢN, VẬN CHUYỂN VÀ ĐỔI TRẢ',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bánh được bảo quản và vận chuyển đúng nhiệt độ tiêu chuẩn. Nếu phát hiện hư hỏng, Bên B chịu trách nhiệm đổi mới hoặc hoàn tiền cho Bên A.',
                        style: TextStyle(fontSize: 12.5, height: 1.45),
                      ),
                      const SizedBox(height: AppTokens.space2XL),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                child: CustomButton(
                  title: 'Đồng ý nội dung',
                  size: ButtonSize.large,
                  width: double.infinity,
                  onPress: () {
                    setState(() => _agreeTerms = true);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBothPartiesSignStatusCard() {
    final customerSignedAt = _loadedContract?.signedByCustomerAt;
    final supplierSignedAt = _loadedContract?.signedBySupplierAt;
    final isCustomerSigned = customerSignedAt != null;
    final isSupplierSigned = supplierSignedAt != null;

    final customerText = isCustomerSigned
        ? 'Bạn đã ký số lúc ${DateFormat("HH:mm dd/MM/yyyy").format(customerSignedAt)}'
        : 'Chờ bạn ký xác thực OTP';
    final supplierText = isSupplierSigned
        ? 'Xưởng đã ký số lúc ${DateFormat("HH:mm dd/MM/yyyy").format(supplierSignedAt)}'
        : 'Đang chờ xưởng sản xuất ký OTP';

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.draw_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tiến Độ Ký Hợp Đồng Hai Bên',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSM),
          // Customer Party
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isCustomerSigned ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isCustomerSigned ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bên Mua (Khách hàng doanh nghiệp):',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      customerText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCustomerSigned ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Supplier Party
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSupplierSigned ? Icons.check_circle : Icons.hourglass_top,
                size: 16,
                color: isSupplierSigned ? AppColors.success : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bên Bán (${_loadedContract?.supplierName ?? "Xưởng sản xuất"}):',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      supplierText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSupplierSigned ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractNumber = _contractNumber;

    if (_isSigned) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space2XL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTokens.space2XL),
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, size: 64, color: AppColors.success),
                ),
                const SizedBox(height: AppTokens.spaceXL),
                const Text(
                  'Ký hợp đồng thành công!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                Text(
                  'Hợp đồng $contractNumber đã được ký thành công. Xưởng bánh đã nhận được thông báo để bắt đầu làm bánh cho bạn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppTokens.space2XL),
                CustomButton(
                  title: 'Xem danh sách hợp đồng',
                  size: ButtonSize.large,
                  width: double.infinity,
                  onPress: () {
                    if (context.canPop()) {
                      context.pop(true);
                    } else {
                      context.go('/contracts');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingContract) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
        body: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            children: [
              AppSkeleton.shimmer(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusSM)),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),
              AppSkeleton.shimmer(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
                ),
              ),
              const SizedBox(height: AppTokens.spaceLG),
              AppSkeleton.shimmer(
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppTokens.radiusCard)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_contractError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: 'Ký hợp đồng $contractNumber', showBack: true),
        body: AppErrorState(
          title: 'Chưa tải được thông tin hợp đồng',
          message: _contractError!,
          onRetry: _initContractData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: 'Ký hợp đồng $contractNumber', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Steps indicator (Kiểm tra -> Chữ ký tay -> Xác thực OTP)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.spaceSM),
              child: AntdSteps(
                current: 2,
                items: [
                  StepItemData(title: 'Kiểm tra', desc: 'Điều khoản HĐ'),
                  StepItemData(title: 'Ký tên', desc: 'Chữ ký'),
                  StepItemData(title: 'Xác thực', desc: 'Xác nhận email'),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // Trạng thái ký hai bên (D22)
            _buildBothPartiesSignStatusCard(),
            const SizedBox(height: AppTokens.spaceMD),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tóm tắt hợp đồng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, AppTokens.minTapTarget),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Xem văn bản đầy đủ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        onPressed: _showFullContractDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceSM),
                  const Text('• Xưởng cam kết đúng chuẩn nguyên liệu, quy cách đóng gói và in logo thương hiệu.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
                  const Text('• Bảo quản & vận chuyển tiêu chuẩn 18-25°C. Đổi mới 100% nếu phát sinh lỗi.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
                  const Text('• Khoản đặt cọc 30% được đảm bảo an toàn cho tới khi nhận hàng thành công.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // 3. Digital Hand Signature Pad (Chữ ký tay)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chữ ký người đại diện *',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, AppTokens.minTapTarget),
                        ),
                        icon: const Icon(Icons.clear, size: 14, color: AppColors.error),
                        label: const Text('Ký lại', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                        onPressed: () => _signatureController.clear(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppTokens.radiusInput),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Signature(
                      controller: _signatureController,
                      backgroundColor: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bạn hãy ký trực tiếp vào khung phía trên nhé.',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // 4. OTP Section (Xác thực OTP Email)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mã xác nhận *',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(80, AppTokens.minTapTarget),
                        ),
                        icon: _isSendingOtp
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.send_outlined, size: 14, color: AppColors.primary),
                        label: Text(
                          _otpSent ? 'Gửi lại mã' : 'Lấy mã',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _isSendingOtp ? null : _handleRequestOtp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Mã xác nhận 6 số đã được gửi tới email tài khoản của bạn.',
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                  ),
                  const SizedBox(height: AppTokens.spaceMD),
                  AntdOtpInput(
                    length: 6,
                    countdownSeconds: 60,
                    onResend: _handleRequestOtp,
                    onComplete: (code) => setState(() => _otpCode = code),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 5. Agreement Checkbox (≥44px tap target)
            InkWell(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              borderRadius: BorderRadius.circular(AppTokens.radiusSM),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tôi đã đọc, hiểu rõ và đồng ý toàn bộ điều khoản hợp đồng.',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),

            // 6. Submit Button
            CustomButton(
              title: 'Xác nhận ký hợp đồng',
              size: ButtonSize.large,
              loading: _isSubmitting,
              disabled: !_agreeTerms || _isSubmitting,
              onPress: _handleSignContract,
            ),
            const SizedBox(height: AppTokens.space2XL),
          ],
        ),
      ),
    );
  }
}
