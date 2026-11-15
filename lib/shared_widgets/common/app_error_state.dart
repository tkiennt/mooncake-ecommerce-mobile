import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'custom_button.dart';

class AppErrorState extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;
  final EdgeInsets padding;

  const AppErrorState({
    super.key,
    this.icon,
    this.title = 'Không thể tải dữ liệu',
    this.message = 'Đã có lỗi xảy ra trong quá trình kết nối. Vui lòng kiểm tra lại mạng và thử lại.',
    this.onRetry,
    this.retryLabel = 'Thử lại',
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.padding = const EdgeInsets.all(AppTokens.space2XL),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container đỏ son hoàng gia
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon ?? Icons.wifi_off_outlined,
                  size: 38,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceLG),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // Message
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spaceSM),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            // Retry CTA (tap target >= 44px)
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spaceXL),
              CustomButton(
                title: retryLabel,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textWhite),
                onPress: onRetry,
                size: ButtonSize.medium,
                variant: ButtonVariant.primary,
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppTokens.spaceSM),
              CustomButton(
                title: secondaryActionLabel!,
                onPress: onSecondaryAction,
                size: ButtonSize.small,
                variant: ButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
