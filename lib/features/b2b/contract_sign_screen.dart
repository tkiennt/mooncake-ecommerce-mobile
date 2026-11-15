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
          content: Text('Mã OTP mẫu: 123456 (hoặc kiểm tra hộp thư email của bạn).'),
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
            content: Text('Mã OTP xác thực ký số đã được gửi tới email của bạn.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi gửi OTP: ${e.toString().replaceFirst('Exception: ', '')}'),
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
        const SnackBar(content: Text('Vui lòng ký tên vào khung chữ ký điện tử.')),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý với các điều khoản hợp đồng trước khi ký.')),
      );
      return;
    }

    if (_otpCode.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ mã OTP 6 chữ số.')),
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
            content: Text('Hợp đồng đã được ký số thành công và chuyển sang xưởng sản xuất!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Lỗi ký hợp đồng: ${e.toString().replaceFirst('Exception: ', '')}'),
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
        'Xưởng sản xuất B2B';

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
                            'Văn Bản Hợp Đồng $_contractNumber',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Điều khoản kinh tế điện tử & cam kết bảo lãnh',
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
                            const Text('BÊN A (BÊN MUA): Quý Khách hàng Doanh Nghiệp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                        'Bên B cam kết sản xuất và đóng gói bánh trung thu thủ công đúng tiêu chuẩn vệ sinh an toàn thực phẩm, bao bì in laser logo độc quyền Bên A đã duyệt. Mọi kiện hàng đều có tem seal nguyên bản.',
                        style: TextStyle(fontSize: 12.5, height: 1.45),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      const Text(
                        'ĐIỀU 2. ĐẶT CỌC KÝ QUỸ VÀ QUYẾT TOÁN',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Đợt 1: Bên A nộp khoản đặt cọc 30% (${_formatCurrency(totalVal * 0.3)}) vào tài khoản ký quỹ trung gian sau khi ký số hợp đồng.\n'
                        '• Đợt 2: Bên A thanh toán 70% giá trị còn lại sau khi đối soát đầy đủ biên bản giao nhận PoD và cảm biến xe lạnh.',
                        style: const TextStyle(fontSize: 12.5, height: 1.45),
                      ),
                      const SizedBox(height: AppTokens.spaceMD),
                      const Text(
                        'ĐIỀU 3. BẢO VẬN XE LẠNH VÀ HOÀN TIỀN 100%',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kiện hàng bắt buộc duy trì nhiệt độ thùng xe từ 18-25°C. Nếu phát hiện móp méo, rách seal hoặc nhiệt độ sai lệch, Bên B chịu trách nhiệm đổi mới hoặc hoàn tiền ngay trong vòng 24 giờ.',
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
                  title: 'Đã đọc và đồng ý nội dung',
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
                  'Ký Số Hợp Đồng Thành Công!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMD),
                Text(
                  'Hợp đồng $contractNumber đã được xác thực an toàn bằng chữ ký điện tử và mã OTP Email. Đối tác sản xuất đã nhận thông báo để tiến hành gia công đơn hàng.',
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
        appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
        body: AppErrorState(
          title: 'Không thể tải thông tin hợp đồng',
          message: _contractError!,
          onRetry: _initContractData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
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
                  StepItemData(title: 'Ký số', desc: 'Chữ ký tay'),
                  StepItemData(title: 'Xác thực', desc: 'OTP Email'),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceMD),

            // 2. Terms & Conditions Card with "Xem văn bản đầy đủ" button (D17)
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
                        'Tóm Tắt Hợp Đồng Kinh Tế',
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
                  const Text('• Bảo quản & vận chuyển bằng xe lạnh chuyên dụng 18-25°C. Đổi mới 100% nếu phát sinh lỗi.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
                  const Text('• Khoản đặt cọc 30% được giữ trong tài khoản ký quỹ an toàn cho tới khi nghiệm thu PoD.', style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textSecondary)),
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
                        'Chữ ký tay người đại diện *',
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
                    'Vui lòng ký tay trực tiếp bằng ngón tay hoặc bút cảm ứng vào khung phía trên.',
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
                        'Mã OTP xác thực ký số *',
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
                          _otpSent ? 'Gửi lại OTP' : 'Lấy mã OTP',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                        onPressed: _isSendingOtp ? null : _handleRequestOtp,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Mã OTP 6 số được gửi tới email tài khoản của bạn để đảm bảo tính pháp lý theo Luật Giao dịch điện tử.',
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
                        'Tôi đã đọc, hiểu rõ và đồng ý toàn bộ điều khoản hợp đồng kinh tế và cam kết ký quỹ bảo đảm.',
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
              title: 'Xác nhận ký số hợp đồng',
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
