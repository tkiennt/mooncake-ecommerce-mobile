import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/antd/antd_otp_input.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String? identifier;

  const VerifyEmailScreen({super.key, this.identifier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Xác Thực OTP', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập mã xác thực',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã OTP 6 số đã được gửi tới ${identifier ?? 'số điện thoại của bạn'}.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            AntdOtpInput(
              onComplete: (otp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xác thực thành công!')),
                );
                context.go('/');
              },
            ),
            const SizedBox(height: 32),

            CustomButton(
              title: 'Xác nhận',
              size: ButtonSize.large,
              width: double.infinity,
              onPress: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }
}
