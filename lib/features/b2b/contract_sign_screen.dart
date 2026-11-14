import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';
import '../../shared_widgets/antd/antd_steps.dart';

class ContractSignScreen extends StatefulWidget {
  final Map<String, dynamic>? contractData;

  const ContractSignScreen({super.key, this.contractData});

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.primary,
    exportBackgroundColor: Colors.transparent,
  );

  bool _agreeTerms = false;
  String _otpCode = '';
  bool _isSigned = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractNumber = widget.contractData?['contractNumber'] ?? 'HD-2026-991';

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
                  StepItemData(title: 'Xác thực', desc: 'Mã OTP SMS'),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ký tên người đại diện pháp luật', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nhập mã OTP xác thực hợp đồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  AntdOtpInput(
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
              onChanged: (val) => setState(() => _agreeTerms = val!),
            ),
            const SizedBox(height: 16),

            CustomButton(
              title: 'Xác nhận ký số hợp đồng',
              size: ButtonSize.large,
              disabled: !_agreeTerms,
              onPress: () {
                if (_signatureController.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng ký tên vào khung chữ ký.')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hợp đồng đã được ký số thành công và chuyển sang xưởng sản xuất!')),
                );
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
