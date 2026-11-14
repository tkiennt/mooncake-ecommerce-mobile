import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String orderCode;

  const PaymentResultScreen({
    super.key,
    this.isSuccess = true,
    this.orderCode = 'DH-2026-9921',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(
        title: 'Kết Quả Thanh Toán',
        showBack: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.successBg : AppColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  size: 48,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Đặt Cọc / Thanh Toán Thành Công!' : 'Giao Dịch Không Thành Công',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Đơn hàng mã $orderCode đã được chuyển sang xưởng sản xuất chuẩn bị nguyên liệu và giao theo lịch hẹn.'
                    : 'Giao dịch bị gián đoạn hoặc hủy bởi người dùng. Bạn có thể thử lại bất cứ lúc nào.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              CustomButton(
                title: 'Xem chi tiết đơn hàng',
                size: ButtonSize.large,
                width: double.infinity,
                onPress: () => context.go('/orders'),
              ),
              const SizedBox(height: 12),
              CustomButton(
                title: 'Về trang chủ',
                variant: ButtonVariant.outline,
                size: ButtonSize.large,
                width: double.infinity,
                onPress: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
