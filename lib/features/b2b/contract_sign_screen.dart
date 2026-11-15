import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/contract.dart';
import '../../data/repositories/contract_repository.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
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
    final num = widget.contractData?['contractNumber'];
    if (num != null && num.toString().isNotEmpty) return num.toString();
    final contract = widget.contractData?['contract'];
    if (contract is ContractModel && contract.contractNumber.isNotEmpty) return contract.contractNumber;
    if (contract is Map && contract['contractNumber'] != null) return contract['contractNumber'].toString();
    return 'HD-2026-991';
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
          content: Text('Mã OTP mô phỏng: 123456 (hoặc kiểm tra email của bạn).'),
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
            content: Text('Lỗi gửi OTP: ${e.toString()}'),
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
            content: Text('Lỗi ký hợp đồng: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractNumber = _contractNumber;

    if (_isSigned) {
      return Scaffold(
        appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, size: 64, color: AppColors.success),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ký Số Hợp Đồng Thành Công!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hợp đồng $contractNumber đã được xác thực bằng chữ ký điện tử và mã OTP an toàn. Xưởng sản xuất sẽ tiến hành chuẩn bị vật tư và lịch sản xuất.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
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

    return Scaffold(
      appBar: AppHeader(title: 'Ký Hợp Đồng $contractNumber', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Steps indicator
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: AntdSteps(
                current: 2,
                items: [
                  StepItemData(title: 'Kiểm tra', desc: 'Điều khoản HĐ'),
                  StepItemData(title: 'Ký số', desc: 'Chữ ký tay'),
                  StepItemData(title: 'Xác thực', desc: 'Mã OTP Email'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Terms & Conditions Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppTokens.shadowSubtle,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tóm Tắt Cam Kết Hợp Đồng B2B', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  SizedBox(height: 8),
                  Text('• Xưởng cam kết đúng chuẩn nguyên liệu, quy cách đóng gói và in logo theo mẫu duyệt.', style: TextStyle(fontSize: 12, height: 1.4)),
                  Text('• Bảo quản & vận chuyển bằng xe lạnh chuyên dụng 20-25°C. Đổi mới 100% nếu phát sinh lỗi bao bì.', style: TextStyle(fontSize: 12, height: 1.4)),
                  Text('• Khoản thanh toán đặt cọc 30% được giữ trong tài khoản ký quỹ an toàn cho tới khi nhận hàng.', style: TextStyle(fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Digital Signature Pad
            Container(
              padding: const EdgeInsets.all(14),
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
                      const Text('Ký tên người đại diện pháp luật *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 14, color: AppColors.error),
                        label: const Text('Ký lại', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        onPressed: () => _signatureController.clear(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Signature(
                      controller: _signatureController,
                      backgroundColor: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // OTP Section
            Container(
              padding: const EdgeInsets.all(14),
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
                      const Text(
                        'Mã OTP xác thực ký số *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: _isSendingOtp
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.send_outlined, size: 14, color: AppColors.primary),
                        label: Text(
                          _otpSent ? 'Gửi lại OTP' : 'Lấy mã OTP',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSendingOtp ? null : _handleRequestOtp,
                      ),
                    ],
                  ),
                  const Text(
                    'Mã OTP 6 số được gửi tới email tài khoản của bạn để đảm bảo tính pháp lý.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  AntdOtpInput(
                    length: 6,
                    countdownSeconds: 60,
                    onResend: _handleRequestOtp,
                    onComplete: (code) => setState(() => _otpCode = code),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Agreement checkbox
            CheckboxListTile(
              value: _agreeTerms,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Tôi đã đọc, hiểu rõ và đồng ý toàn bộ điều khoản hợp đồng kinh tế và cam kết ký quỹ.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (val) => setState(() => _agreeTerms = val ?? false),
            ),
            const SizedBox(height: 16),

            CustomButton(
              title: 'Xác nhận ký số hợp đồng',
              size: ButtonSize.large,
              loading: _isSubmitting,
              disabled: !_agreeTerms || _isSubmitting,
              onPress: _handleSignContract,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
